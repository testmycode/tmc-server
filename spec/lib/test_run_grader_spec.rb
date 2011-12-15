require 'spec_helper'

describe TestRunGrader do
  include GitTestActions

  describe "running tests on a new submission" do
    before :each do
      @submission = Factory.create(:submission, :processed => false)
    end
    
    def half_successful_results
      [
        {
          'className' => 'MyTest',
          'methodName' => 'testSomethingEasy',
          'status' => 'PASSED',
          'pointNames' => ['1.1', '1.2']
        },
        {
          'className' => 'MyTest',
          'methodName' => 'testSomethingDifficult',
          'status' => 'FAILED',
          'pointNames' => ['1.2'],
          'stackTrace' => "frame1\nframe2"
        }
      ]
    end
    
    it "should create test case runs for the submission" do
      TestRunGrader.grade_results(@submission, half_successful_results)
      
      @submission.test_case_runs.should_not be_empty
      tcr = @submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'MyTest testSomethingEasy' }
      tcr.should_not be_nil
      tcr.should be_successful
      tcr.stack_trace.should be_nil
      
      tcr = @submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'MyTest testSomethingDifficult' }
      tcr.should_not be_nil
      tcr.should_not be_successful
      tcr.stack_trace.should == "frame1\nframe2"
    end
    
    it "should not create multiple test case runs for the same test method even if it is involved in multiple points" do
      results = [
        {
          'className' => 'MyTest',
          'methodName' => 'testSomething',
          'status' => 'PASSED',
          'pointNames' => ['1.1', '1.2']
        }
      ]
      
      TestRunGrader.grade_results(@submission, results)
      
      @submission.test_case_runs.count.should == 1
    end

    it "should award points for which all required tests passed" do
      TestRunGrader.grade_results(@submission, half_successful_results)
      
      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should include('1.1')
      points.should_not include('1.2')
    end
    
    it "should only ever award more points, never delete old points" do
      results = [
        {
          'className' => 'MyTest',
          'methodName' => 'one',
          'status' => 'PASSED',
          'pointNames' => ['1.1']
        },
        {
          'className' => 'MyTest',
          'methodName' => 'two',
          'status' => 'FAILED',
          'pointNames' => ['1.2']
        }
      ]
      
      TestRunGrader.grade_results(@submission, results)
      
      results[0]['status'] = 'FAILED'
      results[1]['status'] = 'PASSED'
      
      @submission = Submission.new(
        :user => @submission.user,
        :course => @submission.course,
        :exercise => @submission.exercise
      )
      
      TestRunGrader.grade_results(@submission, results)
      
      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should include('1.1')
      points.should include('1.2')
    end
  end
end
