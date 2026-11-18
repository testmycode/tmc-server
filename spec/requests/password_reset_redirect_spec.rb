# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Password reset requests', type: :request do
  it 'redirects the reset form to courses.mooc.fi' do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'

    get '/password_reset_keys/new'

    expect(response).to redirect_to('https://courses.mooc.fi/reset-password')
  end

  it 'redirects a reset request to courses.mooc.fi without sending mail' do
    SiteSetting.all_settings['courses_mooc_fi_base_url'] = 'https://courses.mooc.fi'
    FactoryBot.create(:user, email: 'student@example.com')

    expect { post '/password_reset_keys', params: { email: 'student@example.com' } }
      .not_to(change { ActionMailer::Base.deliveries.count })
    expect(response).to redirect_to('https://courses.mooc.fi/reset-password')
  end

  it "is unavailable when courses.mooc.fi isn't configured" do
    get '/password_reset_keys/new'

    expect(response).to have_http_status(:service_unavailable)
  end
end
