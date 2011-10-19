require 'spec_helper'

describe Submission do
  describe "when created" do
    before :each do
      @user = mock_model(User)
      @course = mock_model(Course)
      @submission = Submission.new(:user => @user, :course => @course, :exercise_name => 'MyExercise', :return_file_tmp_path => 'the_file.zip')
      
      IO.should_receive(:read).with('the_file.zip').and_return('xoo')
      TestRunner.stub(:run_submission_tests)
    end
  
    it "should ask the test runner to run tests after reading the input file" do
      TestRunner.should_receive(:run_submission_tests).with(@submission)
      
      @submission.should be_valid
      @submission.run_tests
      
      @submission.return_file.should == 'xoo'
    end
    
    it "should catch and store an exception from the test runner" do
      TestRunner.should_receive(:run_submission_tests).with(@submission).and_raise('oh no')
      @submission.run_tests
      @submission.pretest_error.should include('oh no')
    end
  end
  
  describe "validation" do
    before :each do
      @params = {
        :course => mock_model(Course),
        :exercise_name => 'MyExerciseThatDoesntNecessarilyExist',
        :user => mock_model(User)
      }
    end
    
    it "should succeed given valid parameters" do
      Submission.new(@params).should be_valid
    end
    
    it "should require a user" do
      @params.delete :user
      Submission.new(@params).should have(1).error_on(:user)
    end
    
    it "should require an exercise name" do
      @params.delete :exercise_name
      Submission.new(@params).should have(1).error_on(:exercise_name)
    end
    
    it "should take exercise name from given exercise object" do
      @params.delete :exercise_name
      @params[:exercise] = mock_model(Exercise, :name => 'MyExercise123')
      sub = Submission.new(@params)
      sub.should be_valid
      sub.exercise_name.should == 'MyExercise123'
    end
    
    it "should require a course" do
      @params.delete :course
      Submission.new(@params).should have(1).error_on(:course)
    end
  end
  
  it "can summarize test failure messages" do
    #DEPRECATED FEATURE. May be removed after #22 is resolved.
    submission = Submission.new
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo()', :message => 'you fail', :successful => false)
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Yoo hoo()', :successful => true)
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Xoo xoo()', :message => 'you fail again', :successful => false)
    submission.test_failure_messages.should == ['Moo moo() - you fail', 'Xoo xoo() - you fail again']
  end
  
  it "can summarize test failures by category" do
    submission = Submission.new
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo()', :message => 'you fail', :successful => false)
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo2()', :message => 'you fail twice', :successful => false)
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Yoo hoo()', :successful => true)
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Xoo xoo()', :message => 'you fail again', :successful => false)
    submission.categorized_test_failures.should == {
      'Moo' => ['moo() - you fail', 'moo2() - you fail twice'],
      'Xoo' => ['xoo() - you fail again']
    }
  end
end

