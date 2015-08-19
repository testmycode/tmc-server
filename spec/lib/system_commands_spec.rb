require 'spec_helper'

describe SystemCommands do

  it 'should return error on timeout properly' do
    expect {
      sh!('sleep', 2, { timeout: 1 })
    }.to raise_error
  end

  it 'should not return error without timeout set' do
    expect {
      sh!('sleep', 2)
    }.not_to raise_error
  end

  it 'should fail if expecting no output' do
    expect {
      sh!('echo', 'Hello', assert_silent: true)
    }.to raise_error
  end
end
