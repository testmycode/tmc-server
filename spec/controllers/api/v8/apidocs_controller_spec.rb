require 'spec_helper'
require 'json-schema'

describe Api::V8::ApidocsController, type: :controller do
  it 'json provided by controller should be valid swagger' do
    get :index
    json = response.body

    validation = JSON::Validator.validate(File.dirname(__FILE__) + '/swagger-schema.json', json)
    expect(validation).to be_truthy
  end
end
