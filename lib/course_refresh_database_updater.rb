# typed: strict
# frozen_string_literal: true

require 'benchmark'
require 'system_commands'

class CourseRefreshDatabaseUpdater
  extend T::Sig

  # refreshed_course_data: RustLangsCliExecutor.refresh's result. Raises Failure after rolling back.
  sig { params(course: Course, refreshed_course_data: T.untyped).returns(Report) }
  def refresh_course(course, refreshed_course_data)
    Impl.new.refresh_course(course, refreshed_course_data)
  end

  class Report
    extend T::Sig
    sig { void }
    def initialize
      @errors = T.let([], T::Array[String])
      @warnings = T.let([], T::Array[String])
      @notices = T.let([], T::Array[String])
      @timings = T.let({}, T::Hash[Symbol, Benchmark::Tms])
    end

    sig { returns(T::Array[String]) }
    attr_reader :errors
    sig { returns(T::Array[String]) }
    attr_reader :warnings
    sig { returns(T::Array[String]) }
    attr_reader :notices
    sig { returns(T::Hash[Symbol, Benchmark::Tms]) }
    attr_reader :timings
  end

  class Failure < StandardError
    extend T::Sig
    sig { params(report: Report).void }
    def initialize(report)
      super(report.errors.join("\n"))
      @report = report
    end
    sig { returns(Report) }
    attr_reader :report
  end

  class Impl
    extend T::Sig
    include SystemCommands

    sig { void }
    def initialize
      @report = T.let(Report.new, Report)
      @rust_data = T.let({}, T::Hash[String, T.untyped])
      @course = T.let(nil, T.nilable(Course))
    end

    sig { params(method_name: Symbol).void }
    def measure_and_log(method_name)
      log(method_name, Benchmark.measure { method(method_name).call })
    end

    sig { params(method_name: Symbol, result: Benchmark::Tms).void }
    def log(method_name, result)
      Rails.logger.info "Refresh: #{method_name} - #{result}"
      @report.timings[method_name] = result
    end

    sig { params(opts: T::Hash[String, T.untyped]).returns(T::Hash[String, T.untyped]) }
    def merge_course_specific_suboptions(opts)
      if opts.key?('courses') && opts['courses'].key?(course.name)
        opts = opts.merge(opts['courses'][course.name])
      end
      opts.delete 'courses'
      opts
    end

    sig { params(course: Course, data: T.untyped).returns(Report) }
    def refresh_course(course, data)
      @rust_data = data['output-data']
      Course.transaction(requires_new: true) do
        refreshed = Course.find(course.id)
        @course = refreshed

        measure_and_log :update_course_options
        measure_and_log :add_records_for_new_exercises
        measure_and_log :delete_records_for_removed_exercises
        measure_and_log :set_exercise_options
        measure_and_log :set_docker_image
        measure_and_log :update_available_points
        measure_and_log :update_exercise_checksums
        measure_and_log :invalidate_unlocks
        measure_and_log :kafka_publish_exercises

        refreshed.refreshed_at = Time.zone.now
        refreshed.initial_refresh_ready = true unless refreshed.initial_refresh_ready
        refreshed.save!
        refreshed.exercises.each(&:save!)
      rescue StandardError, ScriptError => e
        @report.errors << (e.message + "\n" + T.must(e.backtrace).join("\n"))
        raise ActiveRecord::Rollback
      end

      course.reload
      raise Failure, @report unless @report.errors.empty?
      @report
    end

    # Only valid inside refresh_course's transaction.
    sig { returns(Course) }
    def course
      T.must(@course)
    end

    sig { void }
    def update_course_options
      course.options = merge_course_specific_suboptions(@rust_data['course-options'].clone)
    end

    sig { void }
    def add_records_for_new_exercises
      rust_ex = @rust_data['exercises'].pluck('name')
      course_ex = course.exercises.map { |ex| ex.name }
      added_exercises = rust_ex - course_ex
      added_exercises.each do |exercise|
        @report.notices << "Added exercise #{exercise}"
        course.exercises.new(name: exercise)
      end
    end

    sig { void }
    def delete_records_for_removed_exercises
      removed_exercises = course.exercises.reject { |e| @rust_data['exercises'].map { |ex| ex['name'] }.include?(e.name) }
      removed_exercises.each do |e|
        @report.notices << "Removed exercise #{e.name}"
        course.exercises.destroy(e)
        e.destroy
      end
    end

    sig { void }
    def set_exercise_options
      specs_by_group = course.exercises.reject(&:new_record?).group_by(&:exercise_group_name).transform_values { |es| es.map(&:unlock_spec).uniq }
      course.exercises.each do |e|
        e.has_tests = true # we don't yet detect whether an exercise includes tests
        e.options = {} # exercise metadata.yml reading support removed, set default options
        inherit_group_unlock_spec(e, specs_by_group[e.exercise_group_name] || []) if e.new_record?
        e.disabled! if e.new_record? && course.refreshed?
      end
    end

    # Otherwise a new exercise in a locked group stays open until a teacher re-saves the group's conditions.
    sig { params(exercise: Exercise, specs: T::Array[T.nilable(String)]).void }
    def inherit_group_unlock_spec(exercise, specs)
      if specs.length > 1
        @report.warnings << "Exercise #{exercise.name} was added to a group whose exercises have different unlock conditions; set them on the manage unlocks page"
      elsif specs.first
        exercise.unlock_spec = specs.first
        @report.notices << "Exercise #{exercise.name} inherited the unlock conditions of its group"
      end
    rescue UnlockSpec::InvalidSyntaxError, RuntimeError => e
      @report.warnings << "Exercise #{exercise.name} could not inherit the unlock conditions of its group: #{e.message}"
    end

    sig { void }
    def set_docker_image
      default_image = Exercise.new.docker_image
      @rust_data['exercises'].each do |exercise|
        ex = course.exercises.find { |e| e.name == exercise['name'] }
        next unless ex
        if (exercise['tmcproject-yml'] || {}).include? 'sandbox_image'
          ex.docker_image = exercise['tmcproject-yml']['sandbox_image']
        else
          ex.docker_image = default_image
        end
      end
    end

    sig { void }
    def update_available_points
      @rust_data['exercises'].each do |exercise|
        added = []
        removed = []

        ex = course.exercises.find { |e| e.name == exercise['name'] }
        unless ex
          Rails.logger.warn("Could not find exercise with name #{exercise['name']} in database for course #{course.name}")
          next
        end

        exercise['points'].each do |point_name|
          next unless ex.available_points.none? { |point| point.name == point_name }
          added << point_name
          point = AvailablePoint.create(name: point_name, exercise: ex)
          ex.available_points << point
        end

        ex.available_points.to_a.clone.each do |point|
          if exercise['points'].none?(point.name)
            removed << point.name
            point.destroy
            ex.available_points.destroy(point)
          else
            # TODO: remove point.requires_review; review points are no longer read from metadata.yml
            point.requires_review = false
            point.save!
          end
        end

        @report.notices << "Added points to exercise #{ex.name}: #{added.join(' ')}" unless added.empty?
        @report.notices << "Removed points from exercise #{ex.name}: #{removed.join(' ')}" unless removed.empty?
      end
    end

    sig { void }
    def update_exercise_checksums
      @rust_data['exercises'].each do |exercise|
        ex = course.exercises.find { |e| e.name == exercise['name'] }
        next unless ex
        if ex.checksum != exercise['checksum']
          @report.notices << "Exercise #{ex.name} updated" unless ex.checksum.empty?
          ex.checksum = exercise['checksum']
        end
      end
    end

    sig { void }
    def invalidate_unlocks
      UncomputedUnlock.create_all_for_course(course)
    end

    sig { void }
    def kafka_publish_exercises
      KafkaBatchUpdatePoints.create!(course_id: course.id, task_type: 'exercises') if course.moocfi_id && course.moocfi_id.present?
    end
  end
  private_constant :Impl
end
