# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe SettingsController, type: :controller do
  render_views

  let!(:user) { FactoryBot.create(:user) }
  let(:deletion_url) { 'https://courses.mooc.fi/user-settings/permissions#delete-account' }

  before :each do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'
  end

  it 'links users to account deletion on courses.mooc.fi' do
    controller.current_user = user

    get :show, params: { participant_id: user.id }

    expect(response.body).to include(%(href="#{deletion_url}"))
  end

  it "does not offer an admin the courses.mooc.fi link on another user's settings" do
    controller.current_user = FactoryBot.create(:admin)

    get :show, params: { participant_id: user.id }

    expect(response.body).not_to include(deletion_url)
    expect(response.body).to include('Dangerously destroy account')
  end

  describe 'for an account managed by courses.mooc.fi' do
    before :each do
      user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
      controller.current_user = user
    end

    it 'links to courses.mooc.fi instead of offering the email and password fields' do
      get :show, params: { participant_id: user.id }

      expect(response.body).to include(%(href="https://courses.mooc.fi/user-settings/account"))
      expect(response.body).not_to include('user[email_repeat]')
      expect(response.body).not_to include('user[old_password]')
    end

    it 'refuses submitted email and password changes' do
      expect_any_instance_of(User).not_to receive(:update_password_via_courses_mooc_fi)

      put :update, params: {
        participant_id: user.id,
        user: { email: 'changed@example.com', email_repeat: 'changed@example.com', old_password: 'xooxer', password: 'newpassword', password_repeat: 'newpassword' }
      }

      expect(user.reload.email).not_to eq('changed@example.com')
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include('changed on courses.mooc.fi')
      expect(flash[:notice]).to be_nil
    end

    it 'offers no Save button when there is nothing to edit' do
      allow(UserField).to receive_messages(all: [])

      get :show, params: { participant_id: user.id }

      expect(response.body).not_to include('value="Save"')
    end

    it "points an admin to the user's page on courses.mooc.fi" do
      controller.current_user = FactoryBot.create(:admin)

      get :show, params: { participant_id: user.id }

      expect(response.body).to include(%(href="https://courses.mooc.fi/manage/users/#{user.courses_mooc_fi_user_id}"))
      expect(response.body).not_to include('user[email_repeat]')
      expect(response.body).not_to include('user[old_password]')
    end
  end
end
