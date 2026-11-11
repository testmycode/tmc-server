# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'kafka_updater'

describe KafkaUpdater do
  describe '#update_exercises' do
    it 'publishes only exercises that have a sheet' do
      course = FactoryBot.create(:course, moocfi_id: SecureRandom.hex(16))
      visible = FactoryBot.create(:exercise, course: course, gdocs_sheet: 'osa3')
      FactoryBot.create(:exercise, course: course, gdocs_sheet: nil)
      task = KafkaBatchUpdatePoints.create!(course_id: course.id, task_type: 'exercises')
      updater = KafkaUpdater.new('test', 'secret', 'service')

      expect(updater).to receive(:make_kafka_request).with('exercise', hash_including(data: [hash_including(id: visible.id.to_s, part: 'osa03')]))
      expect(updater.update_exercises(task)).to be(true)
    end
  end
end
