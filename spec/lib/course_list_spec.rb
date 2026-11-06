# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'course_list'

describe CourseList do
  let(:view_context) do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.view_context
  end

  it 'counts the available points of each sheet' do
    exercise = FactoryBot.create(:exercise, gdocs_sheet: 'sheet1')
    course = exercise.course
    FactoryBot.create(:available_point, exercise: exercise)
    FactoryBot.create(:available_point, exercise: exercise)
    admin = FactoryBot.create(:admin)

    data = CourseList.new(admin, view_context).course_data(course.organization, course, include_points: true)

    expect(data[:points]).to eq(sheets: [{ name: 'sheet1', total_available: 2 }], total_available: 2)
  end
end
