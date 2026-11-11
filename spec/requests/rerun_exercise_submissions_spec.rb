# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Rerunning all submissions of an exercise', type: :request do
  let(:course) { FactoryBot.create(:course) }
  let(:exercise) { FactoryBot.create(:exercise, course: course) }
  let(:student) { FactoryBot.create(:user) }
  let!(:submission) { FactoryBot.create(:submission, course: course, exercise: exercise, user: student, processed: true) }

  def rerun_as(user)
    put "/exercises/#{exercise.id}/submissions",
        headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(user.login, user.password) }
  end

  it 'is forbidden for a student' do
    rerun_as(student)
    expect(response).to have_http_status(:forbidden)
    expect(submission.reload).to be_processed
  end

  it 'is allowed for a teacher of the organization' do
    teacher = FactoryBot.create(:user)
    Teachership.create!(user: teacher, organization: course.organization)
    rerun_as(teacher)
    expect(response).to redirect_to("/exercises/#{exercise.id}")
    expect(submission.reload).not_to be_processed
  end
end
