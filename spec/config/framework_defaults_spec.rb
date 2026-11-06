# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Rails 8.0 framework defaults' do
  it 'keeps the receiver time zone in to_time' do
    time = Time.zone.parse('2026-07-01 12:00')
    expect(time.to_time.zone).to eq(Time.zone)
  end

  it 'answers a conditional GET by ETag alone when both validators are sent' do
    request = ActionDispatch::TestRequest.create(
      'HTTP_IF_NONE_MATCH' => '"v1"',
      'HTTP_IF_MODIFIED_SINCE' => 1.day.ago.httpdate
    )
    response = ActionDispatch::Response.new
    response.headers['ETag'] = '"v1"'
    response.last_modified = Time.current
    expect(request.fresh?(response)).to be(true)
  end

  it 'bounds regexp matching time' do
    expect(Regexp.timeout).to eq(1)
  end
end

describe 'Rails 8.1 framework defaults' do
  it 'leaves HTML characters unescaped in rendered JSON responses' do
    expect(ApplicationController.render(json: { key: '<>&' })).to eq('{"key":"<>&"}')
  end

  it 'leaves JavaScript line separators unescaped in JSON' do
    expect(ActiveSupport::JSON.encode("\u2028")).to eq("\"\u2028\"")
  end

  it 'refuses path-relative redirects' do
    controller = ActionController::Base.new
    controller.set_request!(ActionDispatch::TestRequest.create)
    controller.set_response!(ActionDispatch::TestResponse.new)
    expect { controller.redirect_to('example.com') }.to raise_error(ActionController::Redirecting::PathRelativeRedirectError)
  end

  it 'refuses order-dependent finders on models without order columns' do
    expect { MigratedSubmissions.first }.to raise_error(ActiveRecord::MissingRequiredOrderError)
  end

  it 'omits autocomplete from hidden fields' do
    expect(ApplicationController.helpers.hidden_field_tag(:a, 1)).not_to include('autocomplete')
  end
end
