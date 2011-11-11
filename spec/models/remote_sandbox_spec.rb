require 'spec_helper'
require 'thread'

describe RemoteSandbox do

  let(:test_sandbox) { RemoteSandbox.all.first }
  let(:setup) { SubmissionTestSetup.new(:solve => true, :save => true) }
  let(:notify_url) { 'http://localhost:3003/notify' }

  before :all do
    @notify_queue = Queue.new
    notify_queue = @notify_queue # put in closure, blocks below have different `self`
    Mimic.mimic(:port => 3003, :fork => true) do
      post("/notify") do
        notify_queue << params
        [200, {}, ["OK"]]
      end
    end
  end
  
  after :all do
    Mimic.cleanup!
  end

  it "can submit tasks to the remote sandbox" do
    test_sandbox.send_submission(setup.submission, notify_url)
    params = @notify_queue.pop
    params['status'].should == 'finished'
  end
end
