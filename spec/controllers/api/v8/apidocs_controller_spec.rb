# frozen_string_literal: true

require 'spec_helper'
require 'json-schema'

describe Api::V8::ApidocsController, type: :controller do
  it 'json provided by controller should be valid swagger' do
    get :index
    json = response.body

    schema = File.join(Rails.root, 'spec', 'resources', 'swagger-schema.json')
    errors = JSON::Validator.fully_validate(schema, json)
    expect(errors).to be_empty, -> { "Generated apidocs are not valid Swagger 2.0:\n#{errors.join("\n")}" }
  end

  # The Swagger 2.0 JSON schema only requires a path key to start with a slash, so it
  # cannot catch a query string smuggled into the key. Query parameters belong in
  # `parameters`, with `in: query`.
  it 'declares no path containing a query string' do
    get :index

    paths = JSON.parse(response.body)['paths'].keys
    expect(paths.grep(/\?/)).to be_empty
  end
end
