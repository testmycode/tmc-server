# frozen_string_literal: true

class KafkaBatchUpdatePoints < ApplicationRecord
  belongs_to :course

  # Re-enqueue user progress and points updates for a given (course, user) pair.
  #
  # Only considers exercises the user has submitted in that course.
  # Optionally limits to submissions within `interval` (ActiveSupport::Duration).
  #
  # Returns:
  #   { status: :ok, course_id:, user_id:, progress_enqueued:, user_points_enqueued: }
  #   or { status: :skip_<reason>, course_id:, user_id: }
  def self.send_points_again_for_user_and_course(course_id, user_id, interval: nil)
    if interval && !interval.is_a?(ActiveSupport::Duration)
      raise ArgumentError, 'Invalid interval: expected an ActiveSupport::Duration (e.g. 1.week, 3.days)'
    end

    course = Course.find_by(id: course_id)
    return { status: :skip_course_missing, course_id: course_id, user_id: user_id } if course.nil?
    return { status: :skip_no_moocfi_id, course_id: course.id, user_id: user_id } if course.moocfi_id.blank?

    scope = Submission.where(course_id: course.id, user_id: user_id).where.not(exercise_name: [nil, ''])
    scope = scope.where(created_at: (Time.current - interval)..Time.current) if interval

    names = scope.distinct.pluck(:exercise_name)
    return { status: :skip_no_submissions, course_id: course.id, user_id: user_id } if names.empty?

    exercise_ids = Exercise.where(course_id: course.id, name: names).distinct.pluck(:id)
    return { status: :skip_no_matching_exercises, course_id: course.id, user_id: user_id } if exercise_ids.empty?

    transaction do
      create!(course_id: course.id, user_id: user_id, realtime: false, task_type: 'user_progress')
      exercise_ids.each do |exercise_id|
        create!(course_id: course.id, user_id: user_id, exercise_id: exercise_id, realtime: false, task_type: 'user_points')
      end
    end

    { status: :ok, course_id: course.id, user_id: user_id, progress_enqueued: 1, user_points_enqueued: exercise_ids.size }
  end

  # Re-enqueue points for all courses a user has submissions in.
  #
  # Accepts optional `interval` (ActiveSupport::Duration) to restrict submissions.
  # Returns aggregate counts by status and total enqueued items.
  def self.send_points_again_for_user_and_all_courses(user_id, interval: nil)
    if interval && !interval.is_a?(ActiveSupport::Duration)
      raise ArgumentError, 'Invalid interval: expected an ActiveSupport::Duration (e.g. 1.week, 3.days)'
    end

    totals = {
      ok: 0, skip_course_missing: 0, skip_no_moocfi_id: 0, skip_no_submissions: 0, skip_no_matching_exercises: 0,
      progress_enqueued: 0, user_points_enqueued: 0, processed_courses: 0
    }

    Submission.where(user_id: user_id).distinct.pluck(:course_id).each do |course_id|
      r = send_points_again_for_user_and_course(course_id, user_id, interval: interval)
      totals[:processed_courses] += 1
      case r[:status]
      when :ok
        totals[:ok] += 1
        totals[:progress_enqueued] += r[:progress_enqueued]
        totals[:user_points_enqueued] += r[:user_points_enqueued]
      else
        totals[r[:status]] += 1 if totals.key?(r[:status])
      end
    end

    totals
  end

  # Re-enqueue points for all (course, user) pairs with submissions in the last `duration`.
  #
  # Prints a per-batch summary for each batch (`batch_size` pairs per batch),
  # then prints overall totals at the end.
  # Wraps the whole operation in one transaction; if it aborts, prints a clear message.
  # Returns overall totals hash.
  def self.resend_points_for_recent_submissions(duration, batch_size: 1000)
    unless duration.is_a?(ActiveSupport::Duration)
      raise ArgumentError, 'Invalid argument: expected an ActiveSupport::Duration (e.g. 1.week, 3.days)'
    end

    pairs = Submission.where(created_at: (Time.current - duration)..Time.current)
                      .select(:course_id, :user_id)
                      .distinct
                      .pluck(:course_id, :user_id)

    overall = {
      ok: 0, skip_course_missing: 0, skip_no_moocfi_id: 0, skip_no_submissions: 0, skip_no_matching_exercises: 0,
      progress_enqueued: 0, user_points_enqueued: 0, total_pairs: pairs.size
    }

    begin
      transaction do
        pairs.each_slice(batch_size).with_index(1) do |batch_pairs, batch_idx|
          batch = {
            ok: 0, skip_course_missing: 0, skip_no_moocfi_id: 0, skip_no_submissions: 0, skip_no_matching_exercises: 0,
            progress_enqueued: 0, user_points_enqueued: 0, processed_in_batch: batch_pairs.size
          }

          batch_pairs.each do |course_id, user_id|
            r = send_points_again_for_user_and_course(course_id, user_id, interval: duration)
            case r[:status]
            when :ok
              batch[:ok] += 1
              batch[:progress_enqueued] += r[:progress_enqueued]
              batch[:user_points_enqueued] += r[:user_points_enqueued]
            else
              batch[r[:status]] += 1 if batch.key?(r[:status])
            end
          end

          # fold batch into overall
          overall.keys.each do |k|
            next if k == :total_pairs
            overall[k] += batch[k] if batch.key?(k)
          end

          skipped = batch.values_at(:skip_course_missing, :skip_no_moocfi_id, :skip_no_submissions, :skip_no_matching_exercises).sum
          puts(
            "Batch #{batch_idx} (size=#{batch[:processed_in_batch]}): " \
            "ok=#{batch[:ok]}, skipped=#{skipped} " \
            "(missing_course=#{batch[:skip_course_missing]}, no_moocfi=#{batch[:skip_no_moocfi_id]}, " \
            "no_submissions=#{batch[:skip_no_submissions]}, no_match=#{batch[:skip_no_matching_exercises]}), " \
            "enqueued(progress=#{batch[:progress_enqueued]}, user_points=#{batch[:user_points_enqueued]})"
          )
        end
      end

      # Only printed if transaction committed
      total_skipped = overall.values_at(:skip_course_missing, :skip_no_moocfi_id, :skip_no_submissions, :skip_no_matching_exercises).sum
      puts(
        "TOTALS: pairs=#{overall[:total_pairs]}, ok=#{overall[:ok]}, skipped=#{total_skipped} " \
        "(missing_course=#{overall[:skip_course_missing]}, no_moocfi=#{overall[:skip_no_moocfi_id]}, " \
        "no_submissions=#{overall[:skip_no_submissions]}, no_match=#{overall[:skip_no_matching_exercises]}), " \
        "enqueued(progress=#{overall[:progress_enqueued]}, user_points=#{overall[:user_points_enqueued]})"
      )
    rescue => e
      puts "⛔ Transaction aborted in resend_points_for_recent_submissions: #{e.class}: #{e.message}"
      raise
    end

    overall
  end
end
