require 'spec_helper'
require 'thread'

describe RemoteSandbox do

  let(:test_sandbox) { RemoteSandbox.all.first }
  let(:setup) { SubmissionTestSetup.new(:solve => true, :save => true) }

  it "can submit tasks to the remote sandbox" do
    result_hash = RemoteSandboxForTesting.run_submission_get_result_hash(setup.submission)
    
    result_hash['status'].should == 'finished'
    result_hash['token'].should == setup.submission.secret_token
  end
end
