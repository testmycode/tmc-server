require 'find'
require 'pathname'
require 'recursive_yaml_reader'
require 'exercise_dir'
require 'test_scanner'
require 'digest/md5'
require 'tmc_junit_runner'
require 'course_refresher/exercise_file_filter'
require 'maven_cache_seeder'
require 'set'

# Safely refreshes a course from a git repository
class CourseRefresher

  def refresh_course(course)
    Impl.new.refresh_course(course)
  end
  
  class Report
    def initialize
      @errors = []
      @warnings = []
      @notices = []
    end
    attr_reader :errors
    attr_reader :warnings
    attr_reader :notices
    
    def successful?
      @errors.empty?
    end
  end
  
  class Failure < StandardError
    def initialize(report)
      super(report.errors.join("\n"))
      @report = report
    end
    attr_reader :report
  end
  
private

  class Impl
    include SystemCommands
    
    def refresh_course(course)
      @report = Report.new

      Course.transaction(:requires_new => true) do
        begin
          @course = Course.find(course.id, :lock => true)
          
          @old_cache_path = @course.cache_path
          
          @course.cache_version += 1 # causes @course.*_path to return paths in the new cache
          
          FileUtils.rm_rf(@course.cache_path)
          FileUtils.mkdir_p(@course.cache_path)
        
          update_or_clone_repository
          check_directory_names
          update_course_options
          add_records_for_new_exercises
          delete_records_for_removed_exercises
          update_exercise_options
          update_available_points
          make_solutions
          make_stubs
          checksum_stubs
          make_zips_of_stubs
          make_zips_of_solutions
          set_permissions
          @course.save!
          @course.exercises.each &:save!
          
          CourseRefresher.simulate_failure! if ::Rails::env == 'test' && CourseRefresher.respond_to?('simulate_failure!')
        rescue
          @report.errors << $!.message + "\n" + $!.backtrace.join("\n")
          # Delete the new cache we were working on
          FileUtils.rm_rf(@course.cache_path)
          raise ActiveRecord::Rollback
        else
          FileUtils.rm_rf(@old_cache_path)
          seed_maven_cache
        end
      end
      
      course.reload # reload the record given as parameter
      
      raise Failure.new(@report) unless @report.errors.empty?
      @report
    end
    
    def update_or_clone_repository
      raise 'Source types other than git not yet implemented' if @course.source_backend != 'git'

      if File.exists?("#{@old_cache_path}/clone/.git")
        begin
          # Try a fast path: copy old clone and git fetch new stuff
          copy_and_update_repository
        rescue
          FileUtils.rm_rf(@course.clone_path)
          clone_repository
        end
      else
        clone_repository
      end
    end
    
    def copy_and_update_repository
      FileUtils.cp_r("#{@old_cache_path}/clone", "#{@course.clone_path}")
      Dir.chdir(@course.clone_path) do
        sh!('git', 'remote', 'set-url', 'origin', @course.source_url)
        sh!('git', 'fetch', 'origin')
        sh!('git', 'checkout', 'origin/' + @course.git_branch)
      end
    end
    
    def clone_repository
      sh!('git', 'clone', '-q', '-b', @course.git_branch, @course.source_url, @course.clone_path)
    end

    def check_directory_names
      exdirs = exercise_dirs.map {|exdir| Pathname(exdir.path).realpath.to_s }

      Find.find(@course.clone_path) do |path|
        relpath = path[@course.clone_path.length..-1]
        if File.directory?(path) && exdirs.any? {|exdir| exdir.start_with?(path) } && relpath.include?('-')
          raise "The directory #{path} contains a dash (-). Currently that is forbidden. Sorry."
        end
      end
    end
    
    def update_course_options
      options_file = "#{@course.clone_path}/course_options.yml"

      opts = Course.default_options

      if FileTest.exists? options_file
        unless File.read(options_file).strip.empty?
          yaml_data = YAML.load_file(options_file)
          if yaml_data.is_a?(Hash)
            opts = opts.merge(YAML.load_file(options_file))
          end
        end
      end
      @course.options = opts
    end
    
    def exercise_dirs
      @exercise_dirs ||= ExerciseDir.find_exercise_dirs(@course.clone_path)
    end
    
    def exercise_names
      @exercise_names ||= exercise_dirs.map { |ed| ed.name_based_on_path(@course.clone_path) }
    end
    
    def add_records_for_new_exercises
      exercise_names.each do |name|
        if !@course.exercises.any? {|e| e.name == name }
          @report.notices << "Added exercise #{name}"
          exercise = Exercise.new(:name => name)
          @course.exercises << exercise
        end
      end
    end
    
    def delete_records_for_removed_exercises
      removed_exercises = @course.exercises.reject {|e| exercise_names.include?(e.name) }
      removed_exercises.each do |e|
        @report.notices << "Removed exercise #{e.name}"
        @course.exercises.delete(e)
        e.destroy
      end
    end
    
    def update_exercise_options
      reader = RecursiveYamlReader.new
      @review_points = {}
      @course.exercises.each do |e|
        begin
          metadata = reader.read_settings({
            :root_dir => @course.clone_path,
            :target_dir => File.join(@course.clone_path, e.relative_path),
            :file_name => 'metadata.yml',
            :defaults => Exercise.default_options
          })
          @review_points[e.name] = parse_review_points(metadata['review_points'])
          e.options = metadata
          e.save!
        rescue SyntaxError
          @report.errors << "Failed to parse metadata: #{$!}"
        end
      end
    end

    def parse_review_points(data)
      if data == nil
        []
      elsif data.is_a?(String)
        data.split(/\s+/).reject(&:blank?)
      elsif data.is_a?(Array)
        data.map(&:to_s).reject(&:blank?)
      end
    end
    
    def update_available_points
      @course.exercises.each do |exercise|
        review_points = @review_points[exercise.name]
        point_names = Set.new
        point_names += test_case_methods(exercise).map{|x| x[:points]}.flatten
        point_names += review_points

        added = []
        removed = []

        point_names.each do |name|
          if exercise.available_points.none? {|point| point.name == name}
            added << name
            point = AvailablePoint.create(:name => name, :exercise => exercise)
            exercise.available_points << point
          end
        end

        exercise.available_points.to_a.clone.each do |point|
          if point_names.none? {|name| name == point.name}
            removed << point.name
            point.destroy
            exercise.available_points.delete(point)
          else
            point.requires_review = review_points.include?(point.name)
            point.save!
          end
        end

        @report.notices << "Added points to exercise #{exercise.name}: #{added.join(' ')}" unless added.empty?
        @report.notices << "Removed points from exercise #{exercise.name}: #{removed.join(' ')}" unless removed.empty?
      end
    end
    
    def test_case_methods(exercise)
      path = File.join(@course.clone_path, exercise.relative_path)
      TestScanner.get_test_case_methods(@course, exercise.name, path)
    end
    
    def make_solutions
      @course.exercises.each do |e|
        clone_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
        solution_path = Pathname("#{@course.solution_path}/#{e.relative_path}")
        FileUtils.mkdir_p(solution_path)
        ExerciseFileFilter.new(clone_path).make_solution(solution_path)
      end
    end
    
    def make_stubs
      @course.exercises.each do |e|
        clone_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
        stub_path = Pathname("#{@course.stub_path}/#{e.relative_path}")
        FileUtils.mkdir_p(stub_path)
        ExerciseFileFilter.new(clone_path).make_stub(stub_path)

        exercise_type = ExerciseDir.exercise_type(clone_path)
        add_shared_files_to_stub(exercise_type, stub_path)
      end
    end

    def add_shared_files_to_stub(exercise_type, stub_path)
      case exercise_type
      when :java_simple
        FileUtils.mkdir_p(stub_path + 'lib' + 'testrunner')
        FileUtils.cp(TmcJunitRunner.jar_path, stub_path + 'lib' + 'testrunner' + 'tmc-junit-runner.jar')
        FileUtils.cp(TmcJunitRunner.lib_paths, stub_path + 'lib' + 'testrunner')
      else
        # Until NB's Maven API is published, it's convenient to deliver the test runner in the zip like with java_simple.
        FileUtils.mkdir_p(stub_path + 'lib' + 'testrunner')
        FileUtils.cp(TmcJunitRunner.jar_path, stub_path + 'lib' + 'testrunner' + 'tmc-junit-runner.jar')
        FileUtils.cp(TmcJunitRunner.lib_paths, stub_path + 'lib' + 'testrunner')
      end
    end
    
    # Returns a sorted list of relative pathnames to stub files of the exercise.
    # These are checksummed and zipped.
    def stub_files(e)
      sorted_list_of_files_under("#{@course.stub_path}/#{e.relative_path}")
    end

    def solution_files(e)
      sorted_list_of_files_under("#{@course.solution_path}/#{e.relative_path}")
    end

    def sorted_list_of_files_under(dir)
      result = []
      base_path = Pathname(dir)
      Dir.chdir(base_path) do
        Pathname('.').find do |path|
          result << path unless path.to_s == '.'
        end
      end
      result.sort
    end
    
    def checksum_stubs
      @course.exercises.each do |e|
        base_path = Pathname("#{@course.stub_path}/#{e.relative_path}")
        digest = Digest::MD5.new
        Dir.chdir(base_path) do
          stub_files(e).each do |path|
            digest.update(path.to_s)
            digest.file(path.to_s) unless path.directory?
          end
        end
        e.checksum = digest.hexdigest
      end
    end
    
    def make_zips_of_stubs
      FileUtils.mkdir_p(@course.stub_zip_path)
      @course.exercises.each do |e|
        zip_file_path = "#{@course.stub_zip_path}/#{e.name}.zip"
        
        Dir.chdir(@course.stub_path) do
          IO.popen(mk_command(['zip', '--quiet', '-@', zip_file_path]), 'w') do |pipe|
            stub_files(e).each do |path|
              pipe.puts(Pathname(e.relative_path) + path)
            end
          end
        end
      end
    end

    def make_zips_of_solutions
      FileUtils.mkdir_p(@course.solution_zip_path)
      @course.exercises.each do |e|
        zip_file_path = "#{@course.solution_zip_path}/#{e.name}.zip"

        Dir.chdir(@course.solution_path) do
          IO.popen(mk_command(['zip', '--quiet', '-@', zip_file_path]), 'w') do |pipe|
            solution_files(e).each do |path|
              pipe.puts(Pathname(e.relative_path) + path)
            end
          end
        end
      end
    end
    
    def set_permissions
      chmod = SiteSetting.value(:git_repos_chmod)
      chgrp = SiteSetting.value(:git_repos_chgrp)
      
      parent_dirs = Course.cache_root.sub(::Rails.root.to_s, '').split('/').reject(&:blank?)
      for i in 0..(parent_dirs.length)
        dir = "#{::Rails.root}/#{parent_dirs[0..i].join('/')}"
        sh!('chmod', chmod, dir) unless chmod.blank?
        sh!('chgrp', chgrp, dir) unless chgrp.blank?
      end
      
      sh!('chmod', '-R', chmod, @course.cache_path) unless chmod.blank?
      sh!('chgrp', '-R', chgrp, @course.cache_path) unless chgrp.blank?
    end

    def seed_maven_cache
      MavenCacheSeeder.start(@course.clone_path, RemoteSandbox.all)
    end

  end
  
end

