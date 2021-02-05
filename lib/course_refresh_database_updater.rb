# frozen_string_literal: true

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
        @rust_data = data['output-data']
        Course.transaction(requires_new: true) do
          @course = Course.find(course.id)

          measure_and_log :update_course_options
          measure_and_log :add_records_for_new_exercises
          measure_and_log :delete_records_for_removed_exercises
          measure_and_log :set_exercise_options
          measure_and_log :update_available_points
          measure_and_log :update_exercise_checksums
          measure_and_log :invalidate_unlocks
          measure_and_log :kafka_publish_exercises

          @course.refreshed_at = Time.now
          @course.initial_refresh_ready = true unless @course.initial_refresh_ready
          @course.save!
          @course.exercises.each(&:save!)

          CourseRefreshDatabaseUpdater.simulate_failure! if ::Rails.env.test? && CourseRefreshDatabaseUpdater.respond_to?('simulate_failure!')
        rescue StandardError, ScriptError
          @report.errors << $!.message + "\n" + $!.backtrace.join("\n")
          raise ActiveRecord::Rollback
        end

        course.reload # reload the record given as parameter
        raise Failure, @report unless @report.errors.empty?
        @report
      end

      def update_course_options
        @course.options = @rust_data['course-options']
      end

      def add_records_for_new_exercises
        rust_ex = @rust_data['exercises'].map { |ex| ex['name'] }
        course_ex = @course.exercises.map { |ex| ex.name }
        added_exercises = rust_ex - course_ex
        added_exercises.each do |exercise|
          @report.notices << "Added exercise #{exercise}"
          @course.exercises.new(name: exercise)
        end
      end

      def delete_records_for_removed_exercises
        removed_exercises = @course.exercises.reject { |e| @rust_data['exercises'].map { |ex| ex['name'] }.include?(e.name) }
        removed_exercises.each do |e|
          @report.notices << "Removed exercise #{e.name}"
          @course.exercises.destroy(e)
          e.destroy
        end
      end

      def set_exercise_options
        @course.exercises.each do |e|
          e.has_tests = true # we don't yet detect whether an exercise includes tests
          e.disabled! if e.new_record? && e.course.refreshed? # disable new exercises
        end
      end

      def update_available_points
        @rust_data['exercises'].each do |exercise|
          added = []
          removed = []

          ex = @course.exercises.find { |e| e.name == exercise['name'] }
          next unless ex

          exercise['points'].each do |point_name|
            next unless ex.available_points.none? { |point| point.name == point_name }
            added << point_name
            point = AvailablePoint.create(name: point_name, exercise: ex)
            ex.available_points << point
          end

          ex.available_points.to_a.clone.each do |point|
            if exercise['points'].none? { |name| name == point.name }
              removed << point.name
              point.destroy
              ex.available_points.destroy(point)
            else
              # TODO: Review_points and metadata.yml reading removed, point.requires_review functionality should be removed
              point.requires_review = false
              point.save!
            end
          end

          @report.notices << "Added points to exercise #{ex.name}: #{added.join(' ')}" unless added.empty?
          @report.notices << "Removed points from exercise #{ex.name}: #{removed.join(' ')}" unless removed.empty?
        end
      end

      def update_exercise_checksums
        @rust_data['exercises'].each do |exercise|
          ex = @course.exercises.find { |e| e.name == exercise['name'] }
          next unless ex
          if ex.checksum != exercise['checksum']
            @report.notices << "Exercise #{ex.name} updated" unless ex.checksum.empty?
            ex.checksum = exercise['checksum']
          end
        end
      end

      def invalidate_unlocks
        UncomputedUnlock.create_all_for_course(@course)
      end

      def kafka_publish_exercises
        KafkaBatchUpdatePoints.create!(course_id: @course.id, task_type: 'exercises') if @course.moocfi_id
      end
    end
end
