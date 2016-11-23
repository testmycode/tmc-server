require 'spec_helper'
require 'net/http'
require 'uri'

describe Api::V8::ApidocsController, type: :controller do
  it 'json provided by controller should be valid swagger' do
    get :index
    json = response.body

    uri = URI.parse('http://online.swagger.io/validator/debug')
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request.body = json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    expect(response.body).to include('{}')
    expect(response.body).not_to include('schemaValidationMessages')
  end
end
