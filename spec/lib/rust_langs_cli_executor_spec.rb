# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'rust_langs_cli_executor'

describe RustLangsCliExecutor do
  describe '.prepare_submission' do
    def prepare_with_output(output)
      allow(Open3).to receive(:capture2).and_return([output, instance_double(Process::Status)])
      RustLangsCliExecutor.prepare_submission('clone', 'output', 'submission')
    end

    it 'passes client-supplied params to tmc-langs as single arguments, not through a shell' do
      locale = "fi'; touch /tmp/pwned; echo '"
      expect(Open3).to receive(:capture2)
        .with(end_with('/current'), 'prepare-submission', '--clone-path', 'clone', '--output-path', 'output',
              '--submission-path', 'submission', '--tmc-param', "error_msg_locale=#{locale}")
        .and_return(["{\"status\":\"finished\"}\n", instance_double(Process::Status)])
      RustLangsCliExecutor.prepare_submission('clone', 'output', 'submission', { error_msg_locale: locale })
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

  describe '.refresh' do
    it 'passes course template fields to tmc-langs as single arguments, not through a shell' do
      source_url = 'https://example.com/repo.git; touch /tmp/pwned'
      template = FactoryBot.create(:course_template)
      task = CourseTemplateRefresh.create!(course_template: template)
      template.source_url = source_url
      expect(Open3).to receive(:popen2)
        .with(end_with('/current'), 'refresh-course', '--cache-path', template.cache_path, '--cache-root', Course.cache_root,
              '--course-name', template.name, '--git-branch', template.git_branch, '--source-url', source_url)
      RustLangsCliExecutor.refresh(task)
    end
  end
end
