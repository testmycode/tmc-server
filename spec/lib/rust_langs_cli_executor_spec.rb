# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'rust_langs_cli_executor'

describe RustLangsCliExecutor do
  describe '.prepare_submission' do
    def prepare_with_output(output)
      allow(RustLangsCliExecutor).to receive(:`).and_return(output)
      RustLangsCliExecutor.prepare_submission('clone', 'output', 'submission')
    end

    it 'returns the last JSON line' do
      expect(prepare_with_output("{\"status\":\"started\"}\nnoise\n{\"status\":\"finished\"}\n")).to eq('status' => 'finished')
    end

    it 'raises when tmc-langs printed no JSON' do
      expect { prepare_with_output("noise\n") }.to raise_error(RuntimeError, 'TMC-langs-rust printed no JSON output')
    end

    it 'raises with the crash report when tmc-langs crashed' do
      expect { prepare_with_output("{\"status\":\"crashed\",\"message\":\"boom\"}\n") }
        .to raise_error(RuntimeError, 'TMC-langs-rust crashed: {"status":"crashed","message":"boom"}')
    end
  end
end
