# frozen_string_literal: true

require "kafka"


class KafkaBatchUpdatePointsTask
  def initialize
    seed_brokers = SiteSetting.value('kafka_seed_brokers')
    @kafka = seed_brokers && Kafka.new(seed_brokers, client_id: "tmc-server")
  end

  def run
    return unless @kafka
    producer = @kafka.producer
    task = KafkaBatchUpdatePoints.first
    course = task.course
    puts "Batch publishing points for course #{course.name}."

  end

  def wait_delay
    5
  end
end
