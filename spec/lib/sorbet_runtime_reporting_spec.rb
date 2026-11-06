# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe SorbetRuntimeReporting do
  let(:typed_class) do
    Class.new do
      extend T::Sig

      sig { params(count: Integer).returns(Integer) }
      def self.double(count)
        count * 2
      end
    end
  end

  around do |example|
    SorbetRuntimeReporting.install_production_handlers!
    example.run
  ensure
    T::Configuration.call_validation_error_handler = nil
    T::Configuration.inline_type_error_handler = nil
    T::Configuration.sig_validation_error_handler = nil
    T::Configuration.sig_builder_error_handler = nil
    T::Configuration.include_value_in_type_errors
  end

  it 'raises when T.must gets nil' do
    expect { T.must(nil) }.to raise_error(TypeError, /Passed `nil` into T.must/)
  end

  it 'logs a sig violation without the value and carries on' do
    logged = []
    allow(Rails.logger).to receive(:error) { |message| logged << message }
    2.times { expect(typed_class.double('secret')).to eq('secretsecret') }
    expect(logged.size).to eq(1)
    expect(logged.first).to include("Parameter 'count': Expected type Integer, got type String")
    expect(logged.first).not_to include('secret')
  end
end
