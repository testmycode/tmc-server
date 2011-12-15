require 'spec_helper'

describe Submission do
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
  
  it "can summarize test cases" do
    submission = Submission.new
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo()', :message => 'you fail', :successful => false, :stack_trace => "frame1\nframe2")
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo2()', :successful => true)
    submission.test_case_records.should == [
      {
        :name => 'Moo moo()',
        :successful => false,
        :message => 'you fail',
        :stack_trace => "frame1\nframe2"
      },
      {
        :name => 'Moo moo2()',
        :successful => true,
        :message => nil,
        :stack_trace => nil
      }
    ]
  end
  
  it "can tell how many unprocessed submissions are in queue before itself" do
    Factory.create(:submission, :processed => false)
    Factory.create(:submission, :processed => false)
    Factory.create(:submission, :processed => false)
    s = Factory.create(:submission, :processed => false)
    Factory.create(:submission, :processed => false)
    Factory.create(:submission, :processed => false)
    
    s.unprocessed_submissions_before_this.should == 3
  end
end

