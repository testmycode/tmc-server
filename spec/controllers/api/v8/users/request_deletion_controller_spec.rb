# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Users::RequestDeletionController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before do
    allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: user.id, acceptable?: true))
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'
  end

  it 'points the caller to courses.mooc.fi without emailing anything' do
    expect { post :create, params: { user_id: 'current' } }.not_to(change { ActionMailer::Base.deliveries.count })

    expect(response).to have_http_status(410)
    expect(response.parsed_body['account_deletion_url']).to eq('https://courses.mooc.fi/user-settings/permissions#delete-account')
    expect(User.find_by(id: user.id)).to eq(user)
  end
end
