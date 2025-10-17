# frozen_string_literal: true

class KafkaBatchUpdatePoints < ApplicationRecord
  belongs_to :course

  # Optionally restrict to submissions within `interval` (ActiveSupport::Duration)
  # e.g. send_points_again_for_user_and_course(course_id, user_id, interval: 2.weeks)
  def self.send_points_again_for_user_and_course(course_id, user_id, interval: nil)
    if interval && !interval.is_a?(ActiveSupport::Duration)
      raise ArgumentError,
            'Invalid interval: expected an ActiveSupport::Duration (e.g. 1.week, 3.days). ' \
            'Call like: KafkaBatchUpdatePoints.send_points_again_for_user_and_course(42, 7, interval: 1.week)'
    end

    course = Course.find_by!(id: course_id)

    # Skip if course doesn't exist or has no moocfi_id
    if course.moocfi_id.nil? || course.moocfi_id.blank?
      puts "⚠️  Skipping course_id=#{course_id} (missing or empty moocfi_id)"
      return
    end

    submissions_scope = Submission
                          .where(course_id: course.id, user_id: user_id)
                          .where.not(exercise_name: [nil, ''])
    submissions_scope = submissions_scope.where(created_at: (Time.current - interval)..Time.current) if interval

    submitted_names = submissions_scope.distinct.pluck(:exercise_name)
    if submitted_names.empty?
      puts "ℹ️  No submissions found for user_id=#{user_id} in course_id=#{course.id}"
      return
    end

    exercise_ids = Exercise
                     .where(course_id: course.id, name: submitted_names)
                     .distinct
                     .pluck(:id)

    if exercise_ids.empty?
      puts "⚠️  No exercises matched submission names for user_id=#{user_id} in course_id=#{course.id}"
      return
    end

    transaction do
      create!(course_id: course.id, user_id: user_id, realtime: false, task_type: 'user_progress')

      exercise_ids.each do |exercise_id|
        create!(course_id: course.id, user_id: user_id, exercise_id: exercise_id, realtime: false, task_type: 'user_points')
      end
    end

    puts "✅  Resent points for user_id=#{user_id}, course_id=#{course.id} (#{exercise_ids.size} exercises)"
  end

  def self.send_points_again_for_user_and_all_courses(user_id, interval: nil)
    if interval && !interval.is_a?(ActiveSupport::Duration)
      raise ArgumentError,
            'Invalid interval: expected an ActiveSupport::Duration (e.g. 1.week, 3.days). ' \
            'Call like: KafkaBatchUpdatePoints.send_points_again_for_user_and_all_courses(7, interval: 3.days)'
    end

    course_ids = Submission.where(user_id: user_id).distinct.pluck(:course_id)
    puts "🔁  Processing #{course_ids.size} courses for user_id=#{user_id}..."

    course_ids.each do |course_id|
      send_points_again_for_user_and_course(course_id, user_id, interval: interval)
    end
  end

  # Requires an ActiveSupport::Duration, e.g. 1.week, 3.days, etc.
  def self.resend_points_for_recent_submissions(duration)
    unless duration.is_a?(ActiveSupport::Duration)
      raise ArgumentError,
            'Invalid argument: expected an ActiveSupport::Duration (e.g. 1.week, 3.days). ' \
            'Call it like: KafkaBatchUpdatePoints.resend_points_for_recent_submissions(1.week)'
    end

    pairs = Submission
              .where(created_at: (Time.current - duration)..Time.current)
              .select(:course_id, :user_id)
              .distinct
              .pluck(:course_id, :user_id)

    puts "🔍  Found #{pairs.size} (course_id, user_id) pairs in the last #{duration.inspect}"

    processed = 0
    skipped = 0

    transaction do
      pairs.each do |course_id, user_id|
          before = KafkaBatchUpdatePoints.count
          send_points_again_for_user_and_course(course_id, user_id, interval: duration)
          after = KafkaBatchUpdatePoints.count

          if after == before
            skipped += 1
          else
            processed += 1
          end
        end
    end

    puts "✅  Done! Processed #{processed} pairs, skipped #{skipped} (#{pairs.size} total)"
  end
end
