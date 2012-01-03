require 'find'
require 'pathname'
require 'recursive_yaml_reader'
require 'exercise_dir'
require 'test_scanner'
require 'digest/md5'

# Safely refreshes a course from a git repository
class CourseRefresher

  def refresh_course(course)
    Impl.new.refresh_course(course)
  end
  
private

  class Impl
    include SystemCommands
    
    def refresh_course(course)
      Course.transaction(:requires_new => true) do
        @course = Course.find(course.id, :lock => true)
        
        @old_cache_path = @course.cache_path
        @course.cache_version += 1 # causes @course.*_path to return paths in the new cache
        
        FileUtils.rm_rf(@course.cache_path)
        FileUtils.mkdir_p(@course.cache_path)
        
        begin
          clone_repository
          update_course_options
          add_records_for_new_exercises
          delete_records_for_removed_exercises
          update_exercise_options
          update_available_points
          checksum_exercises
          zip_exercises
          set_permissions
          @course.save!
          @course.exercises.each &:save!
        rescue
          begin
            # Delete the new cache we were working on
            FileUtils.rm_rf(@course.cache_path)
          ensure
            raise
          end
        end
        
        FileUtils.rm_rf(@old_cache_path)
      end
      
      course.reload # reload the record given as parameter
    end
  
    
    def clone_repository
      raise 'Source types other than git not yet implemented' if @course.source_backend != 'git'
      sh!('git', 'clone', '-q', @course.source_url, @course.clone_path)
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
        e.options = reader.read_settings({
          :root_dir => @course.clone_path,
          :target_dir => File.join(@course.clone_path, e.relative_path),
          :file_name => 'metadata.yml',
          :defaults => Exercise.default_options
        })
        e.save!
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
    
    def checksum_exercises
      @course.exercises.each do |e|
        base_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
        digest = Digest::MD5.new
        Dir.chdir(base_path) do
          exercise_files_for_zip(e).each do |path|
            digest.update(path.to_s)
            digest.file(path.to_s) unless path.directory?
          end
        end
        e.checksum = digest.hexdigest
      end
    end
    
    # Returns a sorted list of relative pathnames to files of the exercise that should be
    # checksummed and in the zip.
    def exercise_files_for_zip(e)
      result = []
      base_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
      Dir.chdir(base_path) do
        Pathname('.').find do |path|
          if should_skip_file_or_dir(path)
            Find.prune
          else
            result << path unless path.to_s == '.'
          end
        end
      end
      result.sort
    end
    
    def should_skip_file_or_dir(path)
      fn = path.basename.to_s
      [fn.include?('Hidden'), fn.start_with?('.git'), fn == 'metadata.yml'].any?
    end
    
    def zip_exercises
      FileUtils.mkdir_p(@course.zip_path)
      @course.exercises.each do |e|
        base_path = Pathname("#{@course.clone_path}/#{e.relative_path}")
        zip_file_path = "#{@course.zip_path}/#{e.name}.zip"
        
        Dir.chdir(@course.clone_path) do
          IO.popen(mk_command(['zip', '--quiet', '-@', zip_file_path]), 'w') do |pipe|
            exercise_files_for_zip(e).each do |path|
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

