require 'spec_helper'

describe RemoteSandbox do

  let(:test_sandbox) { RemoteSandbox.all.first }
  let(:setup) { SubmissionTestSetup.new(:solve => true, :save => true) }

  it "can submit tasks to the remote sandbox" do
    notify_url = 'http://localhost:3000/'
    test_sandbox.send_submission(setup.submission, notify_url)
    #TODO
  end
end
