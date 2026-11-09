# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe CourseNotification, type: :model do
  it 'saves its topic and message' do
    course = FactoryBot.create(:course)
    sender = FactoryBot.create(:user)

    notification = course.course_notifications.create(topic: 'Hello', message: 'A message', sender_id: sender.id)

    expect(notification).to be_persisted
    expect(notification.reload.topic).to eq('Hello')
    expect(notification.message).to eq('A message')
    expect(notification.sender).to eq(sender)
  end
end
