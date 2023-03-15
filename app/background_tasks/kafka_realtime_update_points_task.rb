# frozen_string_literal: true

require 'kafka_updater'

class KafkaRealtimeUpdatePointsTask
  def initialize
    @kafka_bridge_url = SiteSetting.value('kafka_bridge_url')
    @kafka_bridge_secret = SiteSetting.value('kafka_bridge_secret')
    @service_id = SiteSetting.value('moocfi_service_id')
    @updater = KafkaUpdater.new(@kafka_bridge_url, @kafka_bridge_secret, @service_id)
  end

  def run
    return unless @kafka_bridge_url && @kafka_bridge_secret && @service_id
    return if @kafka_bridge_url.empty? || @kafka_bridge_secret.empty? || @service_id.empty?
    KafkaBatchUpdatePoints.where(realtime: true).each do |task|
      finished_successfully = false
      begin
        type = @updater.task_type(task)
        case type
        when 'user_progress'
          finished_successfully = @updater.update_user_progress(task)
        when 'course_progress'
          finished_successfully = @updater.update_course_progress(task)
        when 'user_points'
          finished_successfully = @updater.update_user_points(task)
        when 'course_points'
          finished_successfully = @updater.update_course_points(task)
        when 'exercises'
          finished_successfully = @updater.update_exercises(task)
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
end
