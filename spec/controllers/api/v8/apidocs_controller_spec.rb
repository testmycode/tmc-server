# frozen_string_literal: true

require 'spec_helper'
require 'json-schema'

describe Api::V8::ApidocsController, type: :controller do
  it 'json provided by controller should be valid swagger' do
    get :index
    json = response.body

    schema = File.join(Rails.root, 'spec', 'resources', 'swagger-schema.json')
    validation = JSON::Validator.validate(schema, json)
    expect(validation).to be_truthy
  end
end
