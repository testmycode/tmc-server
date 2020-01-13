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
    KafkaBatchUpdatePoints.all.each do |task|
      course = task.course
      Rails.logger.info("Batch publishing points for course #{course.name} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
        Rails.logger.error 'Cannot publish points because moocfi id is not specified'
        next
      end
      parts = course.gdocs_sheets
      points_per_user = AwardedPoint.count_per_user_in_course_with_sheet(course, parts)
      Rails.logger.info("Found points for #{points_per_user.keys.length} users")
      available_points = AvailablePoint.course_sheet_points(course, parts)
      points_per_user.each do |username, points_by_group|
        user = User.find_by(login: username)
        Rails.logger.info("Publishing points for user #{user.id}")
        progress = points_by_group.map do |group_name, awareded_points|
          max_points = available_points[group_name] || 0
          {
            group: group_name,
            n_points: awareded_points,
            max_points: max_points,
            progress: (awareded_points / max_points.to_f).floor(2)
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
        RestClient.post("#{@kafka_bridge_url}/api/v0/event", { topic: 'user_course_progress', payload: message }.to_json, { content_type: :json })
      end
      task.destroy!
      puts "Batch publish finished for #{course.name}"
    end
  end

  def wait_delay
    5
  end
end
