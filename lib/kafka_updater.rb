# frozen_string_literal: true

require 'rest-client'

class KafkaUpdater
  def initialize(kafka_bridge_url, kafka_bridge_secret, service_id)
    @kafka_bridge_url = kafka_bridge_url
    @kafka_bridge_secret = kafka_bridge_secret
    @service_id = service_id
  end

  def task_type(task)
    return task.task_type if task.task_type.present?
    'unknown'
  end

  private
    def make_kafka_request(topic, payload)
      return if @kafka_bridge_url == 'test'

      begin
        response = RestClient.post(
          "#{@kafka_bridge_url}/api/v0/event",
          { topic: topic, payload: payload }.to_json,
          content_type: :json,
          authorization: "Basic #{@kafka_bridge_secret}",
          timeout: 30,
          open_timeout: 10
        )
        Rails.logger.debug("Kafka request successful for topic #{topic}")
        response
      rescue RestClient::ExceptionWithResponse => e
        response_body = e.response && e.response.body
        response_body = response_body && response_body.length > 1000 ? "#{response_body[0..1000]}..." : response_body
        Rails.logger.error("Kafka bridge API error for topic #{topic}: #{e.response.code} - #{response_body}")
        raise "Kafka bridge API error: #{e.response.code} - #{response_body}"
      rescue RestClient::Exception => e
        Rails.logger.error("Kafka bridge connection error for topic #{topic}: #{e.message}")
        raise "Kafka bridge connection error: #{e.message}"
      rescue => e
        Rails.logger.error("Unexpected error in Kafka request for topic #{topic}: #{e.message}")
        raise "Unexpected Kafka error: #{e.message}"
      end
    end

    def update_user_progress(task)
      finished_successfully = false
      user = User.find(task.user_id)
      course = Course.find(task.course_id)
      Rails.logger.info("Publishing progress for user #{user.id} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id || course.moocfi_id.blank?
        Rails.logger.error('Cannot publish progress because moocfi id is not specified')
        return finished_successfully
      end
      parts = course.gdocs_sheets
      points_per_user = AwardedPoint.count_per_user_in_course_with_sheet(course, parts, user)
      available_points = AvailablePoint.course_sheet_points(course, parts)
      unless points_per_user[user.username]
        Rails.logger.info('No points found. Skipping')
        return true
      end
      progress = points_per_user[user.username].map do |group_name, awarded_points|
        max_points = available_points[group_name] || 0
        stupid_name = "osa#{group_name.tr('^0-9', '').rjust(2, "0")}"
        {
          group: stupid_name,
          n_points: awarded_points,
          max_points: max_points,
          progress: (awarded_points / max_points.to_f).floor(2)
        }
      end
      message = {
        timestamp: Time.zone.now.iso8601,
        user_id: user.id,
        course_id: course.moocfi_id,
        service_id: @service_id,
        progress: progress,
        message_format_version: 1
      }
      topic = task.realtime ? 'user-course-progress-realtime' : 'user-course-progress-batch'
      make_kafka_request(topic, message)
      Rails.logger.info("Publishing progress finished for user #{user.id}")
      finished_successfully = true
      finished_successfully
    end

    def update_course_progress(task)
      finished_successfully = false
      course = Course.find(task.course_id)
      Rails.logger.info("Batch publishing progress for course #{course.name} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
        Rails.logger.error('Cannot publish progress because moocfi id is not specified')
        return finished_successfully
      end
      parts = course.gdocs_sheets
      points_per_user = AwardedPoint.count_per_user_in_course_with_sheet(course, parts)
      Rails.logger.info("Found points for #{points_per_user.keys.length} users")
      available_points = AvailablePoint.course_sheet_points(course, parts)
      points_per_user.each do |username, points_by_group|
        current_user = User.find_by(login: username)
        Rails.logger.info("Publishing progress for user #{current_user.id}")
        progress = points_by_group.map do |group_name, awarded_points|
          max_points = available_points[group_name] || 0
          stupid_name = "osa#{group_name.tr('^0-9', '').rjust(2, "0")}"
          {
            group: stupid_name,
            n_points: awarded_points,
            max_points: max_points,
            progress: (awarded_points / max_points.to_f).floor(2)
          }
        end
        message = {
          timestamp: Time.zone.now.iso8601,
          user_id: current_user.id,
          course_id: course.moocfi_id,
          service_id: @service_id,
          progress: progress,
          message_format_version: 1
        }
        make_kafka_request('user-course-progress-batch', message)
        Rails.logger.info("Publishing progress finished for user #{current_user.id}")
      end
      Rails.logger.info("Batch publishing progress finished for course #{course.name}")
      finished_successfully = true
      finished_successfully
    end

    def update_user_points(task)
      finished_successfully = false
      course = Course.find(task.course_id)
      user = User.find(task.user_id)
      Rails.logger.info("Publishing points for user #{user.id} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
        Rails.logger.error('Cannot publish points because moocfi id is not specified. Removing extra task (this task never should have been created.)')
        task.destroy!
        return finished_successfully
      end
      exercise = Exercise.find(task.exercise_id)
      awarded_points = exercise.points_for(user)
      completed = exercise.completed_by?(user)
      message = {
        timestamp: Time.zone.now.iso8601,
        exercise_id: exercise.id.to_s,
        n_points: awarded_points.length,
        completed: completed,
        attempted: true,
        user_id: user.id,
        course_id: course.moocfi_id,
        service_id: @service_id,
        required_actions: [],
        message_format_version: 1
      }
      topic = task.realtime ? 'user-points-realtime' : 'user-points-batch'
      make_kafka_request(topic, message)
      Rails.logger.info("Publishing points finished for user #{user.id}")
      finished_successfully = true
      finished_successfully
    end

    def update_course_points(task)
      finished_successfully = false
      course = Course.find(task.course_id)
      Rails.logger.info("Batch publishing points for course #{course.name} with moocfi id: #{course.moocfi_id}")
      if !course.moocfi_id
        Rails.logger.error('Cannot publish points because moocfi id is not specified')
        return finished_successfully
      end
      parts = course.gdocs_sheets
      points_per_user = AwardedPoint.count_per_user_in_course_with_sheet(course, parts)
      Rails.logger.info("Found points for #{points_per_user.keys.length} users")
      exercises = Exercise.where(course_id: course.id).where(disabled_status: 0)
      points_per_user.each do |username, _points_by_group|
        current_user = User.find_by(login: username)
        Rails.logger.info("Publishing points for user #{current_user.id}")
        exercises_data = []
        exercises.map do |exercise|
          awarded_points = exercise.points_for(current_user)
          completed = exercise.completed_by?(current_user)
          user_submissions = exercise.submissions_by(current_user)
          attempted = user_submissions.length > 0
          original_submission_date = user_submissions.pluck(:created_at).sort.first
          original_submission_date_str = original_submission_date.strftime('%FT%T%:z') unless original_submission_date.nil?
          exercises_data << {
            timestamp: Time.zone.now.iso8601,
            exercise_id: exercise.id.to_s,
            n_points: awarded_points.length,
            completed: completed,
            attempted: attempted,
            user_id: current_user.id,
            course_id: course.moocfi_id,
            service_id: @service_id,
            required_actions: [],
            original_submission_date: original_submission_date_str,
            message_format_version: 1
          }
        end
        message = {
          timestamp: Time.zone.now.iso8601,
          user_id: current_user.id,
          course_id: course.moocfi_id,
          exercises: exercises_data,
          message_format_version: 1
        }
        make_kafka_request('user-course-points-batch', message)
        Rails.logger.info("Publishing points finished for user #{current_user.id}")
      end
      Rails.logger.info("Batch publishing points finished for course #{course.name}")
      finished_successfully = true
      finished_successfully
    end

    def update_exercises(task)
      finished_successfully = false
      course = Course.find(task.course_id)
      Rails.logger.info("Batch publishing exercises for course #{course.name} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
        Rails.logger.error('Cannot publish exercises because moocfi id is not specified')
        return finished_successfully
      end
      exercises = Exercise.where(course_id: course.id).where(disabled_status: 0)
      data = exercises.map do |exercise|
        max_points = AvailablePoint.where(exercise_id: exercise.id).count
        stupid_name = "osa#{exercise.gdocs_sheet.tr('^0-9', '').rjust(2, "0")}"
        exerciseData = {
          name: exercise.name,
          id: exercise.id.to_s,
          part: stupid_name,
          section: 0,
          max_points: max_points
        }
        exerciseData
      end
      message = {
        timestamp: Time.zone.now.iso8601,
        course_id: course.moocfi_id,
        service_id: @service_id,
        data: data,
        message_format_version: 1
      }
      make_kafka_request('exercise', message)
      Rails.logger.info("Batch publishing exercises finished for course #{course.name}")
      finished_successfully = true
      finished_successfully
    end

    def update_user_course_points(task)
      finished_successfully = false
      course = Course.find(task.course_id)
      user = User.find(task.user_id)
      Rails.logger.info("Publishing points for user #{user.id} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
        Rails.logger.error('Cannot publish points because moocfi id is not specified')
        return finished_successfully
      end
      exercises = []
      course.exercises.each do |exercise|
        awarded_points = exercise.points_for(user)
        completed = exercise.completed_by?(user)
        user_submissions = exercise.submissions_by(user)
        attempted = user_submissions.length > 0
        original_submission_date = user_submissions.pluck(:created_at).sort.first
        original_submission_date_str = original_submission_date.strftime('%FT%T%:z') unless original_submission_date.nil?
        exercises << {
          timestamp: Time.zone.now.iso8601,
          exercise_id: exercise.id.to_s,
          n_points: awarded_points.length,
          completed: completed,
          attempted: attempted,
          user_id: user.id,
          course_id: course.moocfi_id,
          service_id: @service_id,
          required_actions: [],
          original_submission_date: original_submission_date_str,
          message_format_version: 1
        }
      end
      message = {
        timestamp: Time.zone.now.iso8601,
        user_id: user.id,
        course_id: course.moocfi_id,
        exercises: exercises,
        message_format_version: 1
      }
      topic = task.realtime ? 'user-course-points-realtime' : 'user-course-points-batch'
      make_kafka_request(topic, message)
      Rails.logger.info("Publishing points finished for user #{user.id}")
      finished_successfully = true
      finished_successfully
    end
end
