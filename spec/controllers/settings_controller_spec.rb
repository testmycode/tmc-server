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
end
