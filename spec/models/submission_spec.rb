require 'spec_helper'

describe Submission do
  describe "when created" do
    before :each do
      @submission = Submission.new(:student_id => '123xyz', :return_file_tmp_path => 'the_file.zip')
      
      IO.should_receive(:read).with('the_file.zip').and_return('xoo')
      TestRunner.stub(:run_submission_tests)
    end
  
    it "should ask the test runner to run tests after reading the input file" do
      TestRunner.should_receive(:run_submission_tests).with(@submission)
      
      @submission.should be_valid
      @submission.save!
      
      @submission.return_file.should == 'xoo'
    end
    
    it "should catch and store an exception from the test runner" do
      TestRunner.should_receive(:run_submission_tests).with(@submission).and_raise('oh no')
      @submission.save!
      @submission.reload
      @submission.pretest_error.should include('oh no')
    end
  end
end

