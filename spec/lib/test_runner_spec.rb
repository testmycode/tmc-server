require 'spec_helper'

describe TestRunner do
  include GitTestActions

  describe "running tests on a submission" do
    before :each do
      @course = Course.create!(:name => 'MyCourse')
      @repo = clone_course_repo(@course)
      @repo.copy_simple_exercise
      @repo.add_commit_push
      @course.refresh
      
      @exercise_dir = SimpleExercise.new('MyExercise')
      @exercise = @course.exercises.first
      
      @user = User.create!(:login => 'student', :password => 'student')
      @submission = Submission.new(
        :user => @user,
        :exercise => @exercise,
        :return_file_tmp_path => 'MyExercise.zip'
      )
    end
    
    it "should create test results for the submission" do
      @exercise_dir.solve_add
      @exercise_dir.make_zip
      TestRunner.run_submission_tests(@submission)
      
      @submission.test_case_runs.should_not be_empty
      tcr = @submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'SimpleTest testAdd' }
      tcr.should_not be_nil
      tcr.should be_successful
      
      tcr = @submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'SimpleTest testSubtract' }
      tcr.should_not be_nil
      tcr.should_not be_successful
      
      @submission.should be_valid
      @submission.save!
    end
    
    it "should not create test results for the same test method even if it is involved in multiple points"
    
    it "should raise an error if compilation of a test fails" do
      @exercise_dir.introduce_compilation_error
      @exercise_dir.make_zip
      expect { TestRunner.run_submission_tests(@submission) }.to raise_error(/Compilation error/)
    end
    
    it "should award points for successful exercises" do
      @exercise_dir.solve_sub
      @exercise_dir.make_zip
      TestRunner.run_submission_tests(@submission)
      @submission.save!
      
      points = @user.awarded_points_for_course(@course).to_a
      points.find {|ap| ap.name == 'justsub' }.should_not be_nil
      points.find {|ap| ap.name == 'addsub' }.should be_nil
      points.find {|ap| ap.name == 'mul' }.should be_nil
    end
    
    it "should only ever award more points, never delete old points" do
      @exercise_dir.solve_sub
      @exercise_dir.make_zip
      TestRunner.run_submission_tests(@submission)
      @submission.save!
      
      @submission = Submission.new(
        :user => @user,
        :exercise => @exercise,
        :return_file_tmp_path => 'MyExercise.zip'
      )
      
      @exercise_dir.solve_add
      @exercise_dir.make_zip
      TestRunner.run_submission_tests(@submission)
      @submission.save!
      
      points = @user.awarded_points_for_course(@course).to_a
      points.find {|ap| ap.name == 'justsub' }.should_not be_nil
      points.find {|ap| ap.name == 'addsub' }.should_not be_nil
      points.find {|ap| ap.name == 'mul' }.should be_nil
    end
  end
end
