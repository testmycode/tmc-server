# frozen_string_literal: true

require 'kafka'

class KafkaBatchUpdatePointsTask
  def initialize
    seed_brokers = SiteSetting.value('kafka_seed_brokers')
    @service_id = SiteSetting.value('kafka_service_id')
    @kafka = seed_brokers && Kafka.new(seed_brokers, client_id: 'tmc-server')
  end

  def run
    return unless @kafka && @service_id
    producer = @kafka.producer
    KafkaBatchUpdatePoints.all.each do |task|
      course = task.course
      Rails.logger.info("Batch publishing points for course #{course.name} with moocfi id: #{course.moocfi_id}.")
      if !course.moocfi_id
        Rails.logger.error 'Cannot publish points because moocfi id is not specified'
        next
      end
      points_per_user = AwardedPoint.count_per_user_in_course_with_sheet(course, course.gdocs_sheets)
      Rails.logger.info("Found points for #{parts.keys.length} users")
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
        producer.deliver_message(message, topic: 'user-course-progress')
      end
    end
  end

  def wait_delay
    5
  end
end
