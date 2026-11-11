# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Client IP resolution' do
  def remote_ip(headers)
    config = Rails.application.config.action_dispatch
    app = ->(env) { [200, {}, [ActionDispatch::Request.new(env).remote_ip]] }
    ActionDispatch::RemoteIp.new(app, config.ip_spoofing_check, config.trusted_proxies).call({ 'REMOTE_ADDR' => '10.0.0.1' }.merge(headers))[2].first
  end

  it 'takes the client from X-Forwarded-For behind a private proxy' do
    expect(remote_ip('HTTP_X_FORWARDED_FOR' => '203.0.113.7')).to eq('203.0.113.7')
  end

  it 'accepts Forwarded and X-Forwarded-For that name the same client' do
    expect(remote_ip('HTTP_X_FORWARDED_FOR' => '203.0.113.7', 'HTTP_FORWARDED' => 'for=203.0.113.7')).to eq('203.0.113.7')
  end

  it 'takes the client from Forwarded when it is the only proxy header' do
    expect(remote_ip('HTTP_FORWARDED' => 'for=203.0.113.7')).to eq('203.0.113.7')
  end

  it 'rejects Forwarded and X-Forwarded-For that name different clients' do
    expect { remote_ip('HTTP_X_FORWARDED_FOR' => '203.0.113.7', 'HTTP_FORWARDED' => 'for=198.51.100.9') }
      .to raise_error(ActionDispatch::RemoteIp::IpSpoofAttackError)
  end

  it 'rejects a Client-Ip that X-Forwarded-For does not contain' do
    expect { remote_ip('HTTP_X_FORWARDED_FOR' => '203.0.113.7', 'HTTP_CLIENT_IP' => '198.51.100.9') }
      .to raise_error(ActionDispatch::RemoteIp::IpSpoofAttackError)
  end
end
