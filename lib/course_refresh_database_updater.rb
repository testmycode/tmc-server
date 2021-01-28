# frozen_string_literal: true

require 'find'
require 'pathname'
require 'recursive_yaml_reader'
require 'exercise_dir'
require 'test_scanner'
require 'digest/md5'
require 'course_refresher/exercise_file_filter'
require 'maven_cache_seeder'
require 'set'
require 'fileutils'
require 'benchmark'

class CourseRefreshDatabaseUpdater
  def refresh_course(course, refreshed_course_data)
    Impl.new.refresh_course(course, refreshed_course_data)
  end

  class Report
    def initialize
      @errors = []
      @warnings = []
      @notices = []
      @timings = {}
    end

    attr_reader :errors
    attr_reader :warnings
    attr_reader :notices
    attr_reader :timings
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

      def measure_and_log(method_name, *args)
        log(method_name, Benchmark.measure { send(method_name, *args) })
      end

      def log(method_name, result)
        Rails.logger.info "Refresh: #{method_name} - #{result}"
        @report.timings[method_name] = result
      end

      def refresh_course(course, data)
        @report = Report.new
        @rust_data = data
        Course.transaction(requires_new: true) do
          @course = Course.find(course.id)

          @cache_path = @course.cache_path

          # @cache_path = data['new-cache-path']
          # @course.cache_path = @cache_path

          measure_and_log :update_course_options
          measure_and_log :add_records_for_new_exercises
          measure_and_log :delete_records_for_removed_exercises
          measure_and_log :set_has_tests_flags
          # measure_and_log :update_available_points, options[:no_directory_changes] unless options[:no_background_operations]
          measure_and_log :checksum_stubs
          measure_and_log :invalidate_unlocks
          measure_and_log :kafka_publish_exercises

          @course.course_template.save!
          @course.refreshed_at = Time.now
          @course.initial_refresh_ready = true unless @course.initial_refresh_ready
          @course.save!
          @course.exercises.each(&:save!)

          CourseRefresher.simulate_failure! if ::Rails.env.test? && CourseRefresher.respond_to?('simulate_failure!')
        rescue StandardError, ScriptError
          @report.errors << $!.message + "\n" + $!.backtrace.join("\n")
          raise ActiveRecord::Rollback
        end

        if @report.errors.empty? # && !options[:no_directory_changes]
          seed_maven_cache
        end

        course.reload # reload the record given as parameter
        raise Failure, @report unless @report.errors.empty?
        @report
      end

      # Implement from Rust data
      def update_course_options
        options_file = "#{@course.clone_path}/course_options.yml"

        opts = {}

        if FileTest.exists? options_file
          unless File.read(options_file).strip.empty?
            yaml_data = YAML.load_file(options_file)
            if yaml_data.is_a?(Hash)
              opts = YAML.load_file(options_file)
              opts = merge_course_specific_suboptions(opts)
            end
          end
        end
        @course.options = opts
        # @course.options = data['course-options']
      end

      # Implement, set
      def add_records_for_new_exercises
        @rust_data['new_exercises'].each do |exercise|
          unless @course.exercises.any? { |e| e.name == exercise }
            @report.notices << "Added exercise #{exercise}"
            @course.exercises.new(name: exercise)
          end
        end
        # exercise_names.each do |name|
        #   unless @course.exercises.any? { |e| e.name == name }
        #     @report.notices << "Added exercise #{name}"
        #     @course.exercises.new(name: name)
        #   end
        # end
      end

      # Implement
      def delete_records_for_removed_exercises
        removed_exercises = @course.exercises.reject { |e| @rust_data['new_exercises'].map { |ex| ex }.include?(e.name) }
        # removed_exercises = @course.exercises.reject { |e| exercise_names.include?(e.name) }
        removed_exercises.each do |e|
          @report.notices << "Removed exercise #{e.name}"
          @course.exercises.destroy(e)
          e.destroy
        end
      end

      def parse_review_points(data)
        if data.nil?
          []
        elsif data.is_a?(String)
          data.split(/\s+/).reject(&:blank?)
        elsif data.is_a?(Array)
          data.map(&:to_s).reject(&:blank?)
        end
      end

      def merge_course_specific_suboptions(opts)
        if opts['courses'].is_a?(Hash) && opts['courses'][@course.name].is_a?(Hash)
          opts = opts.merge(opts['courses'][@course.name])
        end
        opts.delete 'courses'
        opts
      end

      # Can be implemented in any exercise loop
      def set_has_tests_flags
        @course.exercises.each do |e|
          e.has_tests = true # we don't yet detect whether an exercise includes tests
        end
      end

      def update_available_points(no_directory_changes = false)
        @course.exercises.each do |exercise|
          point_names = Set.new

          points_data = points_for(exercise, no_directory_changes)
          point_names += if points_data[0].is_a? Hash
            points_data.map { |x| x[:points] }.flatten
          else
            points_data.flatten
          end

          added = []
          removed = []

          point_names.each do |name|
            next unless exercise.available_points.none? { |point| point.name == name }
            added << name
            point = AvailablePoint.create(name: name, exercise: exercise)
            exercise.available_points << point
          end

          exercise.available_points.to_a.clone.each do |point|
            if point_names.none? { |name| name == point.name }
              removed << point.name
              point.destroy
              exercise.available_points.destroy(point)
            else
              # Review_points and metadata.yml reading deprecated
              point.requires_review = false
              point.save!
            end
          end

          @report.notices << "Added points to exercise #{exercise.name}: #{added.join(' ')}" unless added.empty?
          @report.notices << "Removed points from exercise #{exercise.name}: #{removed.join(' ')}" unless removed.empty?
        end
      end

      # Deprecated, moved to langs-rust?
      def points_for(exercise, no_directory_changes = false)
        # TODO: cache this in the template
        if no_directory_changes
          course = exercise.course
          other_course = course.course_template.courses.where(initial_refresh_ready: true).first
          if other_course && !other_course.available_points.count.zero? && course != other_course
            other_exercise = other_course.exercises.find_by(name: exercise.name)
            return other_exercise.available_points.pluck(:name) if other_exercise
          end
        end
        path = File.join(@course.clone_path, exercise.relative_path)
        TestScanner.get_test_case_methods(@course, exercise.name, path)
      end

      # Deprecated, checksum calc in rust, only need to update to DB
      def checksum_stubs
        # @course.exercises.each do |e|
        #   base_path = Pathname("#{@course.stub_path}/#{e.relative_path}")
        #   digest = Digest::MD5.new
        #   Dir.chdir(base_path) do
        #     stub_files(e).each do |path|
        #       digest.update(path.to_s)
        #       digest.file(path.to_s) unless path.directory?
        #     end
        #   end
        #   e.checksum = digest.hexdigest
        # end
      end

      def invalidate_unlocks
        UncomputedUnlock.create_all_for_course(@course)
      end

      def seed_maven_cache
        MavenCacheSeeder.start(@course.clone_path, RemoteSandbox.all)
      end

      def kafka_publish_exercises
        KafkaBatchUpdatePoints.create!(course_id: @course.id, task_type: 'exercises') if @course.moocfi_id
      end
    end
end
