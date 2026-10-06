# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Users::RequestDeletionController, type: :controller do
  let(:user) { FactoryBot.create(:user, courses_mooc_fi_user_id: SecureRandom.uuid) }

  around do |example|
    original = Rails.configuration.x.accept_courses_mooc_fi_tokens
    Rails.configuration.x.accept_courses_mooc_fi_tokens = true
    example.run
    Rails.configuration.x.accept_courses_mooc_fi_tokens = original
  end

  it 'refuses a deletion request made with a courses.mooc.fi access token' do
    allow(controller).to receive(:doorkeeper_token).and_return(nil)
    request.headers['Authorization'] = 'Bearer sp331-access-token'
    allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(
      CoursesMoocFiTokenIntrospector::Result.new(sub: user.courses_mooc_fi_user_id)
    )
    expect(UserMailer).not_to receive(:destroy_confirmation)

    post :create, params: { user_id: 'current' }

    expect(response).to have_http_status(403)
  end
end
