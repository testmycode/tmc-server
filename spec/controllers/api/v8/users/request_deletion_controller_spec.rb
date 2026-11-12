# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Users::RequestDeletionController, type: :controller do
  let(:user) { FactoryBot.create(:user, courses_mooc_fi_user_id: SecureRandom.uuid) }
  let(:application) { Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }

  def authenticate(scopes: 'public')
    token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: scopes)
    request.headers['Authorization'] = "Bearer #{token.token}"
  end

  around do |example|
    original = Rails.configuration.x.accept_courses_mooc_fi_tokens
    Rails.configuration.x.accept_courses_mooc_fi_tokens = true
    example.run
    Rails.configuration.x.accept_courses_mooc_fi_tokens = original
  end

  before do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'
  end

  it 'points the caller to courses.mooc.fi without emailing anything' do
    authenticate

    expect { post :create, params: { user_id: 'current' } }.not_to(change { ActionMailer::Base.deliveries.count })

    expect(response).to have_http_status(410)
    expect(response.parsed_body['account_deletion_url']).to eq('https://courses.mooc.fi/user-settings/permissions#delete-account')
    expect(User.find_by(id: user.id)).to eq(user)
  end

  it "says to contact support when courses.mooc.fi isn't configured" do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = nil
    authenticate

    post :create, params: { user_id: 'current' }

    expect(response).to have_http_status(410)
    expect(response.parsed_body['errors']).to eq(['Please contact support to delete your account.'])
    expect(response.parsed_body['account_deletion_url']).to be_nil
  end

  it 'requires authentication' do
    post :create, params: { user_id: 'current' }

    expect(response).to have_http_status(401)
  end

  it 'refuses a deletion request made with a courses.mooc.fi access token' do
    request.headers['Authorization'] = 'Bearer sp331-access-token'
    allow(CoursesMoocFiTokenIntrospector).to receive(:introspect).and_return(
      CoursesMoocFiTokenIntrospector::Result.new(sub: user.courses_mooc_fi_user_id)
    )

    post :create, params: { user_id: 'current' }

    expect(response).to have_http_status(403)
  end

  it 'refuses a deletion request made with a handoff token' do
    authenticate(scopes: 'public handoff')

    post :create, params: { user_id: 'current' }

    expect(response).to have_http_status(403)
  end
end
