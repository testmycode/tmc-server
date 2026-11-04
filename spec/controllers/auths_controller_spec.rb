# frozen_string_literal: true

require 'spec_helper'

describe AuthsController, type: :controller do
  before :each do
    @user = FactoryBot.create(:user, login: 'foo', password: 'bar')
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
end
