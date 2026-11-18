# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe MailRateLimit do
  it 'allows a first send' do
    expect(MailRateLimit.allowed?([])).to be(true)
  end

  it 'refuses a send within the minimum interval' do
    expect(MailRateLimit.allowed?([1.minute.ago])).to be(false)
  end

  it 'refuses a fourth send within the window' do
    expect(MailRateLimit.allowed?([1.hour.ago, 2.hours.ago, 3.hours.ago])).to be(false)
  end

  it 'ignores sends outside the window' do
    expect(MailRateLimit.allowed?([25.hours.ago, 26.hours.ago, 27.hours.ago])).to be(true)
  end
end
