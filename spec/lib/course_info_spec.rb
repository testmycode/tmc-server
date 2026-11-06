# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'course_info'

describe CourseInfo do
  let(:view_context) do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.view_context
  end

  it "reports the user's latest submission of each exercise" do
    user = FactoryBot.create(:user)
    exercise = FactoryBot.create(:exercise)
    course = exercise.course
    FactoryBot.create(:submission, course: course, exercise: exercise, user: user, created_at: 2.days.ago)
    latest = FactoryBot.create(:submission, course: course, exercise: exercise, user: user, created_at: 1.day.ago)
    FactoryBot.create(:submission, course: course, exercise: exercise, user: user, created_at: 3.days.ago)

    data = CourseInfo.new(user, view_context).course_data(course.organization, course)

    expect(data[:exercises].map { |e| e[:latest_submission_id] }).to eq([latest.id])
  end
end
