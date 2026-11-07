# typed: strict
# frozen_string_literal: true

require 'kafka_updater'

class KafkaRealtimeUpdatePointsTask
  extend T::Sig
  sig { void }
  def initialize
    @kafka_bridge_url = T.let(SiteSetting.value('kafka_bridge_url'), T.nilable(String))
    @kafka_bridge_secret = T.let(SiteSetting.value('kafka_bridge_secret'), T.nilable(String))
    @service_id = T.let(SiteSetting.value('moocfi_service_id'), T.nilable(String))
    @updater = T.let(KafkaUpdater.new(@kafka_bridge_url, @kafka_bridge_secret, @service_id), KafkaUpdater)
  end

  sig { void }
  def run
    return unless @kafka_bridge_url && @kafka_bridge_secret && @service_id
    return if @kafka_bridge_url.empty? || @kafka_bridge_secret.empty? || @service_id.empty?
    KafkaBatchUpdatePoints.where(realtime: true).find_each do |task|
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
        when 'user_course_points'
          finished_successfully = @updater.update_user_course_points(task)
        else
          Rails.logger.error("Cannot process task #{task.id} because task.task_type is not defined")
        end
      rescue => e
        Rails.logger.error("Task failed: #{e.class.name}: #{e.message}")
        backtrace = e.backtrace
        Rails.logger.error("Task failed backtrace: #{backtrace.join("\n")}") if backtrace
      end
      task.destroy! if finished_successfully
    end
  end

  sig { returns(Integer) }
  def wait_delay
    5
  end
end
