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
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo()', :message => 'you fail', :successful => false, :exception => '{"a": "b"}')
    submission.test_case_runs << TestCaseRun.new(:test_case_name => 'Moo moo2()', :successful => true)
    submission.test_case_records.should == [
      {
        :name => 'Moo moo()',
        :successful => false,
        :message => 'you fail',
        :exception => {'a' => 'b'}
      },
      {
        :name => 'Moo moo2()',
        :successful => true,
        :message => nil,
        :exception => nil
      }
    ]
  end

  it "can tell how many unprocessed submissions are in queue before itself" do
    t = Time.now
    Factory.create(:submission, :processed => false, :processing_tried_at => t - 10.seconds)
    Factory.create(:submission, :processed => false, :processing_tried_at => t - 9.seconds)
    Factory.create(:submission, :processed => false, :processing_tried_at => t - 8.seconds, :processing_priority => -2)
    Factory.create(:submission, :processed => false, :processing_tried_at => t - 7.seconds)
    s = Factory.create(:submission, :processed => false, :processing_tried_at => t - 6.seconds)
    Factory.create(:submission, :processed => false, :processing_tried_at => t - 5.seconds)
    Factory.create(:submission, :processed => false, :processing_tried_at => t - 4.seconds)
    
    s.unprocessed_submissions_before_this.should == 3
  end

  it "orders unprocessed submissions by priority, then by last processing attempt time" do
    t = Time.now
    s1 = Factory.create(:submission, :processed => false, :processing_tried_at => t - 7.seconds)
    s2 = Factory.create(:submission, :processed => false, :processing_tried_at => t - 8.seconds)
    s3 = Factory.create(:submission, :processed => false, :processing_tried_at => t - 9.seconds, :processing_priority => 1)
    s4 = Factory.create(:submission, :processed => false, :processing_tried_at => t - 10.seconds)

    expected_order = [s3, s4, s2, s1]

    Submission.to_be_reprocessed.map(&:id).should == expected_order.map(&:id)
  end

  it "stores stdout and stderr compressed" do
    s = Factory.create(:submission)
    s.stdout = "hello"
    s.stdout_compressed.should_not be_empty
    s.stderr = "world"
    s.stderr_compressed.should_not be_empty
    s.save!

    s = Submission.find(s.id)
    s.stdout.should == "hello"
    s.stderr.should == "world"
  end

  it "can have null stdout and stderr" do
    s = Factory.create(:submission)
    s.stdout = "hello"
    s.stdout_compressed.should_not be_empty
    s.stderr = "world"
    s.stderr_compressed.should_not be_empty
    s.stdout = nil
    s.stdout.should be_nil
    s.stderr = nil
    s.stderr.should be_nil
    s.save!
  end
end

