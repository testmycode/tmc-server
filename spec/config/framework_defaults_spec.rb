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
