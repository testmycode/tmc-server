# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Self-service account deletion', type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:token) { VerificationToken.create!(user: user, type: :delete_user) }
  let(:deletion_url) { 'https://courses.mooc.fi/user-settings/permissions#delete-account' }

  before :each do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'
  end

  it 'redirects an emailed deletion link to courses.mooc.fi' do
    get "/users/#{user.id}/destroy/#{token.token}"

    expect(response).to redirect_to(deletion_url)
  end

  it 'redirects the old deletion form without deleting the user' do
    delete "/users/#{user.id}/destroy/#{token.token}", params: { im_sure: '1', user: { password: user.password } }

    expect(response).to redirect_to(deletion_url)
    expect(User.find_by(id: user.id)).to eq(user)
  end

  it 'redirects a deletion email request without sending email' do
    expect { post "/users/#{user.id}/send_destroy_email" }.not_to(change { ActionMailer::Base.deliveries.count })

    expect(response).to redirect_to(deletion_url)
  end

  it 'redirects a stale deletion form when forgery protection is on' do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post "/users/#{user.id}/send_destroy_email", params: { authenticity_token: 'stale' }

    expect(response).to redirect_to(deletion_url)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  it "sends the user to their account page, which says to contact support, when courses.mooc.fi isn't configured" do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = nil

    get "/users/#{user.id}/destroy/#{token.token}"

    expect(response).to redirect_to(user_path)
  end
end
