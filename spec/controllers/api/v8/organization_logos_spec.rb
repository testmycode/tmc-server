# typed: false
# frozen_string_literal: true

require 'spec_helper'

# The vscode extension's webview loads `<root><logo_path>` itself, and
# `<root>/logos/small_logo/missing.png` when logo_path ends in missing.png.
describe 'Organization logos the clients load', type: :request do
  let(:organization) { FactoryBot.create(:accepted_organization) }

  it 'serves the placeholder logo' do
    get '/logos/small_logo/missing.png'
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('image/png')
  end

  it 'serves an uploaded logo at the logo_path the API lists' do
    organization.logo.attach(io: StringIO.new(Vips::Image.black(300, 120).pngsave_buffer), filename: 'logo.png', content_type: 'image/png')
    get "/api/v8/org/#{organization.slug}.json"
    logo_path = response.parsed_body['logo_path']
    expect(logo_path).to start_with('/')

    get logo_path
    get response.location while response.redirect?
    expect(response).to have_http_status(:ok)
    expect(Vips::Image.new_from_buffer(response.body, '').width).to eq(100)
  end
end
