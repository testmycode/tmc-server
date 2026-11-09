# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::Exercises::DetailsController, type: :controller do
  let(:visible_exercise) { FactoryBot.create(:exercise) }
  let(:hidden_course_exercise) { FactoryBot.create(:exercise, course: FactoryBot.create(:course, hidden: true)) }

  before :each do
    allow(controller).to receive(:doorkeeper_token).and_return(nil)
  end

  def query_count(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  it 'leaves out exercises of courses the caller cannot read' do
    get :show, params: { ids: "#{visible_exercise.id},#{hidden_course_exercise.id}" }
    expect(response).to have_http_status(200)
    expect(response.parsed_body['exercises'].pluck('id')).to eq([visible_exercise.id])
  end

  it 'leaves out hidden exercises of a readable course' do
    hidden_exercise = FactoryBot.create(:exercise, course: visible_exercise.course, hidden: true)
    get :show, params: { ids: "#{visible_exercise.id},#{hidden_exercise.id}" }
    expect(response.parsed_body['exercises'].pluck('id')).to eq([visible_exercise.id])
  end

  it 'gives a teacher the hidden exercises of their course' do
    hidden_exercise = FactoryBot.create(:exercise, course: visible_exercise.course, hidden: true)
    teacher = FactoryBot.create(:user)
    Teachership.create!(user: teacher, organization: visible_exercise.course.organization)
    allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: teacher.id, acceptable?: true))
    get :show, params: { ids: "#{visible_exercise.id},#{hidden_exercise.id}" }
    expect(response.parsed_body['exercises'].pluck('id')).to contain_exactly(visible_exercise.id, hidden_exercise.id)
  end

  it 'runs the same number of queries for 2 and 6 exercises' do
    user = FactoryBot.create(:user)
    allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: user.id, acceptable?: true))
    course = visible_exercise.course
    exercises = [visible_exercise] + FactoryBot.create_list(:exercise, 5, course: course)
    exercises.last.update!(hidden: true)

    few = query_count { get :show, params: { ids: exercises.first(2).map(&:id).join(',') } }
    expect(response.parsed_body['exercises'].size).to eq(2)
    many = query_count { get :show, params: { ids: exercises.map(&:id).join(',') } }
    expect(response.parsed_body['exercises'].size).to eq(5)
    expect(many).to eq(few)
  end
end
