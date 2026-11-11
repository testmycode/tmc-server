# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe AuthsController, type: :controller do
  before :each do
    @user = FactoryBot.create(:user, login: 'foo', password: 'bar')
    allow_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).and_return(true)
  end

  it 'tells whether the given user/password is valid or not' do
    get :show, params: { username: 'foo', password: 'bar', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('OK')

    get :show, params: { username: 'foo', password: 'wrong', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('FAIL')

    get :show, params: { username: 'wrong', password: 'bar', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('FAIL')
  end

  it 'should work with POST as well' do
    post :show, params: { username: 'foo', password: 'bar', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('OK')

    post :show, params: { username: 'foo', password: 'wrong', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('FAIL')

    post :show, params: { username: 'wrong', password: 'bar', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('FAIL')
  end

  it 'should work with an existing session' do
    Session.create!(session_id: 'foo', data: { 'user_id' => @user.id })
    s = Session.last
    expect(s).not_to be_nil
    post :show, params: { username: 'foo', session_id: s.session_id, format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('OK')
  end

  it 'accepts an access token only while it is not revoked' do
    application = Doorkeeper::Application.create!(name: 'client', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')
    token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: @user.id, scopes: 'public')

    post :show, params: { username: 'foo', session_id: token.token, format: :text }
    expect(response.body).to eq('OK')

    token.revoke
    post :show, params: { username: 'foo', session_id: token.token, format: :text }
    expect(response.body).to eq('FAIL')
  end

  it 'fails without a username' do
    get :show, params: { password: 'bar', format: :text }
    expect(response).to be_successful
    expect(response.body).to eq('FAIL')
  end

  it 'checks the password of an externally managed user with courses.mooc.fi' do
    @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
    expect_any_instance_of(User).to receive(:courses_mooc_fi_authentication_status).with('bar').and_return(:rejected)
    get :show, params: { username: 'foo', password: 'bar', format: :text }
    expect(response.body).to eq('FAIL')
  end

  it 'refuses the local password of a user flagged as externally managed without an id' do
    @user.update_column(:password_managed_by_courses_mooc_fi, true)
    get :show, params: { username: 'foo', password: 'bar', format: :text }
    expect(response.body).to eq('FAIL')
  end
end
