# frozen_string_literal: true

require 'rest-client'

class KafkaBatchUpdatePointsTask
  def initialize
    @kafka_bridge_url = SiteSetting.value('kafka_bridge_url')
    @kafka_bridge_secret = SiteSetting.value('kafka_bridge_secret')
    @service_id = SiteSetting.value('moocfi_service_id')
  end

  def run
    return unless @kafka_bridge_url && @kafka_bridge_secret && @service_id
    return if @kafka_bridge_url.empty? || @kafka_bridge_secret.empty? || @service_id.empty?
    KafkaBatchUpdatePoints.all.each do |task|
      finished_successfully = false
      begin
        type = task_type(task)
        case type
        when 'user_progress'
          finished_successfully = update_user_progress(task)
        when 'course_progress'
          finished_successfully = update_course_progress(task)
        when 'user_points'
          finished_successfully = update_user_points(task)
        when 'course_points'
          finished_successfully = update_course_points(task)
        when 'exercises'
          finished_successfully = update_exercises(task)
        else
          Rails.logger.error("Cannot process task #{task.id} because task.task_type is not defined")
        end
      rescue => e
        Rails.logger.error("Task failed: #{e}")
      end
      task.destroy! if finished_successfully
    end
  end

  def wait_delay
    5
  end

  private

    def task_type(task)
      return task.task_type if task.task_type.present?
      'unknown'
    end

    def update_user_progress(task)
      finished_successfully = false
      user = User.find(task.user_id)
      course = Course.find(task.course_id)
      Rails.logger.info("Publishing progress for user #{user.id} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
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
      RestClient.post("#{@kafka_bridge_url}/api/v0/event", { topic: topic, payload: message }.to_json, content_type: :json, authorization: "Basic #{@kafka_bridge_secret}")
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
        RestClient.post("#{@kafka_bridge_url}/api/v0/event", { topic: 'user-course-progress-batch', payload: message }.to_json, content_type: :json, authorization: "Basic #{@kafka_bridge_secret}")
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
        Rails.logger.error('Cannot publish points because moocfi id is not specified')
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
      RestClient.post("#{@kafka_bridge_url}/api/v0/event", { topic: topic, payload: message }.to_json, content_type: :json, authorization: "Basic #{@kafka_bridge_secret}")
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
        exercises.map do |exercise|
          awarded_points = exercise.points_for(current_user)
          completed = exercise.completed_by?(current_user)
          attempted = !exercise.submissions_by(current_user).empty?
          message = {
            timestamp: Time.zone.now.iso8601,
            exercise_id: exercise.id.to_s,
            n_points: awarded_points.length,
            completed: completed,
            attempted: attempted,
            user_id: current_user.id,
            course_id: course.moocfi_id,
            service_id: @service_id,
            required_actions: [],
            message_format_version: 1
          }
          RestClient.post("#{@kafka_bridge_url}/api/v0/event", { topic: 'user-points-batch', payload: message }.to_json, content_type: :json, authorization: "Basic #{@kafka_bridge_secret}")
        end
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
      RestClient.post("#{@kafka_bridge_url}/api/v0/event", { topic: 'exercise', payload: message }.to_json, content_type: :json, authorization: "Basic #{@kafka_bridge_secret}")
      Rails.logger.info("Batch publishing exercises finished for course #{course.name}")
      finished_successfully = true
      finished_successfully
    end
end
