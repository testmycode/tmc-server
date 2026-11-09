# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'OAuth application page', type: :request do
  it 'labels the confidentiality with a single colon' do
    allow_any_instance_of(Doorkeeper::ApplicationsController).to receive(:authenticate_admin!)
    application = Doorkeeper::Application.create!(name: 'Client', redirect_uri: 'https://example.com/callback')

    get "/oauth/applications/#{application.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<h4>Confidential:</h4>')
  end
end
