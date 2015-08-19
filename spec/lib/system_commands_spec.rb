require 'spec_helper'

describe SystemCommands do

  it 'should return error when when command exit status is non-zero' do
    expect {
      sh!('false')
    }.to raise_error
  end

  it 'should return error on timeout properly' do
    expect {
      sh!('sleep', 2, { timeout: 1 })
    }.to raise_error(/timeout/)
  end

  it 'should fail if expecting no output' do
    expect {
      sh!('echo', 'Hello', assert_silent: true)
    }.to raise_error(/Expected no output/)
  end
end
