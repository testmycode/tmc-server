# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'submission_packager'

describe SubmissionPackager do
  it 'packages a submission that has no params' do
    submission = FactoryBot.create(:submission, return_file: 'zip')
    submission.params = nil
    expect(RustLangsCliExecutor).to receive(:prepare_submission).with(anything, anything, anything, {}, anything) do |_clone, output_path|
      File.write(output_path, 'packaged')
    end

    expect(SubmissionPackager.new.get_full_zip(submission)).to eq('packaged')
  end
end
