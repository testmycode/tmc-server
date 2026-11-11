# typed: false
# frozen_string_literal: true

require 'spec_helper'

shared_context 'a failing paste submission' do
  let(:course) { FactoryBot.create(:course) }
  let(:exercise) { FactoryBot.create(:exercise, course: course) }
  let(:owner) { FactoryBot.create(:user) }
  let(:other_student) { FactoryBot.create(:user) }
  let(:teacher) do
    FactoryBot.create(:user).tap { |t| Teachership.create!(user: t, organization: course.organization) }
  end
  let(:submission) do
    FactoryBot.create(:submission, course: course, exercise: exercise, user: owner,
                                   paste_available: true, all_tests_passed: false)
  end

  before { FactoryBot.create(:submission_data, submission: submission) }
end

describe FullZipController, type: :controller do
  include_context 'a failing paste submission'

  before { allow_any_instance_of(SubmissionPackager).to receive(:get_full_zip).and_return('zip') }

  def download_as(user)
    controller.current_user = user if user
    get :index, params: { submission_id: submission.id }
  end

  it 'refuses another student' do
    download_as(other_student)
    expect(response).to have_http_status(:forbidden)
  end

  it 'refuses an anonymous user' do
    download_as(nil)
    expect(response).to redirect_to(%r{/login})
  end

  it 'lets the owner download' do
    download_as(owner)
    expect(response).to have_http_status(:ok)
  end

  it 'lets a teacher download' do
    download_as(teacher)
    expect(response).to have_http_status(:ok)
  end
end

describe Api::V8::Core::SubmissionsController, type: :controller do
  include_context 'a failing paste submission'

  def download_as(user)
    token = user && Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public')
    allow(controller).to receive(:doorkeeper_token) { token }
    get :download, params: { id: submission.id }
  end

  it 'refuses another student' do
    download_as(other_student)
    expect(response).to have_http_status(:forbidden)
  end

  it 'refuses an anonymous user' do
    download_as(nil)
    expect(response).to have_http_status(:unauthorized).or have_http_status(:forbidden)
  end

  it 'lets the owner download' do
    download_as(owner)
    expect(response).to have_http_status(:ok)
  end

  it 'lets a teacher download' do
    download_as(teacher)
    expect(response).to have_http_status(:ok)
  end
end
