# frozen_string_literal: true

require 'spec_helper'

describe SystemCommands do
  it 'should return error when when command exit status is non-zero' do
    expect do
      sh!('false')
    end.to raise_error
  end

  it 'should return error on timeout properly' do
    expect do
      sh!('sleep', 2, timeout: 1)
    end.to raise_error(/timeout/)
  end

  it 'should fail if expecting no output' do
    expect do
      sh!('echo', 'Hello', assert_silent: true)
    end.to raise_error(/Expected no output/)
  end
end
