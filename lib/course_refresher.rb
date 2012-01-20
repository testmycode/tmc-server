require 'find'
require 'pathname'
require 'recursive_yaml_reader'
require 'exercise_dir'
require 'test_scanner'
require 'digest/md5'
require 'tmc_junit_runner'
require 'course_refresher/exercise_file_filter'

# Safely refreshes a course from a git repository
class CourseRefresher

  def refresh_course(course)
    Impl.new.refresh_course(course)
  end
  
  class Report
    def initialize
      @errors = []
      @warnings = []
    end
    attr_reader :errors
    attr_reader :warnings
    
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

      begin      
        Course.transaction(:requires_new => true) do
          @course = Course.find(course.id, :lock => true)
          
          @old_cache_path = @course.cache_path
          
          @course.cache_version += 1 # causes @course.*_path to return paths in the new cache
          
          FileUtils.rm_rf(@course.cache_path)
          FileUtils.mkdir_p(@course.cache_path)
        
          update_or_clone_repository
          update_course_options
          add_records_for_new_exercises
          delete_records_for_removed_exercises
          update_exercise_options
          update_available_points
          make_solutions
          make_stubs
          checksum_stubs
          make_zips_of_stubs
          set_permissions
          @course.save!
          @course.exercises.each &:save!
          
          CourseRefresher.simulate_failure! if ::Rails::env == 'test' && CourseRefresher.respond_to?('simulate_failure!')
        end
      rescue
        @report.errors << $!.message + "\n" + $!.backtrace.join("\n")
        # Delete the new cache we were working on
        FileUtils.rm_rf(@course.cache_path)
      else
        FileUtils.rm_rf(@old_cache_path)
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
    
    def update_course_options
      options_file = "#{@course.clone_path}/course_options.yml"

      if FileTest.exists? options_file
        @course.options = Course.default_options.merge(YAML.load_file(options_file))
      else
        @course.options = Course.default_options
      end
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
          exercise = Exercise.new(:name => name)
          @course.exercises << exercise
        end
      end
    end
    
    def delete_records_for_removed_exercises
      removed_exercises = @course.exercises.reject {|e| exercise_names.include?(e.name) }
      removed_exercises.each do |e|
        @course.exercises.delete(e)
        e.destroy
      end
    end
    
    def update_exercise_options
      reader = RecursiveYamlReader.new
      @course.exercises.each do |e|
        begin
          e.options = reader.read_settings({
            :root_dir => @course.clone_path,
            :target_dir => File.join(@course.clone_path, e.relative_path),
            :file_name => 'metadata.yml',
            :defaults => Exercise.default_options
          })
          e.save!
        rescue SyntaxError
          @report.errors << "Failed to parse metadata: #{$!}"
        end
      end
    end
    
    def update_available_points
      @course.exercises.each do |exercise|
        point_names = test_case_methods(exercise).map{|x| x[:points]}.flatten.uniq

        point_names.each do |name|
          if exercise.available_points.none? {|point| point.name == name}
            point = AvailablePoint.create(:name => name, :exercise => exercise)
            exercise.available_points << point
          end
        end

        exercise.available_points.each do |point|
          if point_names.none? {|name| name == point.name}
            point.destroy
            exercise.available_points.delete(point)
          end
        end
      end
    end
    
    def test_case_methods(exercise)
      path = File.join(@course.clone_path, exercise.relative_path)
      TestScanner.get_test_case_methods(path)
    end
    
    def make_solutions
      @course.exercises.each do |e|
        clone_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
        solution_path = Pathname("#{@course.solution_path}/#{e.relative_path}")
        FileUtils.mkdir_p(solution_path)
        ExerciseFileFilter.new.make_solution(clone_path, solution_path)
      end
    end
    
    def make_stubs
      @course.exercises.each do |e|
        clone_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
        stub_path = Pathname("#{@course.stub_path}/#{e.relative_path}")
        FileUtils.mkdir_p(stub_path)
        ExerciseFileFilter.new.make_stub(clone_path, stub_path)
        
        FileUtils.mkdir_p(stub_path + 'lib' + 'testrunner')
        FileUtils.cp(TmcJunitRunner.jar_path, stub_path + 'lib' + 'testrunner' + 'tmc-junit-runner.jar')
        FileUtils.cp(TmcJunitRunner.lib_paths, stub_path + 'lib' + 'testrunner')
      end
    end
    
    # Returns a sorted list of relative pathnames to stub files of the exercise.
    # These are checksummed and zipped.
    def stub_files(e)
      result = []
      base_path = Pathname("#{@course.stub_path}/#{e.relative_path}")
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
      FileUtils.mkdir_p(@course.zip_path)
      @course.exercises.each do |e|
        zip_file_path = "#{@course.zip_path}/#{e.name}.zip"
        
        Dir.chdir(@course.stub_path) do
          IO.popen(mk_command(['zip', '--quiet', '-@', zip_file_path]), 'w') do |pipe|
            stub_files(e).each do |path|
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
  
  end
  
end

