# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Basic auth challenge on JSON 403 responses', type: :request do
  let(:course) { FactoryBot.create(:course, hidden: true) }
  let(:path) { "/org/#{course.organization.slug}/courses/#{course.id}/exercise_status/someone.json" }

  def get_status(client_params)
    get path, params: { api_version: ApiVersion::API_VERSION }.merge(client_params)
  end

  it 'is not sent to NetBeans plugins that send no version' do
    get_status(client: 'netbeans_plugin')
    expect(response).to have_http_status(:forbidden)
    expect(response.headers['WWW-Authenticate']).to be_nil
  end

  it 'is not sent to NetBeans plugins older than 0.8.0' do
    get_status(client: 'netbeans_plugin', client_version: '0.7.9')
    expect(response).to have_http_status(:forbidden)
    expect(response.headers['WWW-Authenticate']).to be_nil
  end

  it 'is sent to NetBeans plugins from 0.8.0 on' do
    get_status(client: 'netbeans_plugin', client_version: '0.8.0')
    expect(response).to have_http_status(:forbidden)
    expect(response.headers['WWW-Authenticate']).to eq('Basic realm="Forbidden"')
  end
end
