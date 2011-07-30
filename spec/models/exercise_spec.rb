require 'spec_helper'

describe Exercise do
  include GitTestActions
  
  let(:user) { Factory.create(:user) }
  let(:course) { Factory.create(:course) }

  describe "when read from a course repo" do
    before :each do
      @course_name = 'MyCourse'
      FileUtils.mkdir_p 'bare_repo'
      copy_model_repo("bare_repo/#{@course_name}")
      system! "git clone -q bare_repo/#{@course_name} #{@course_name}"
      @repo = GitRepo.new(@course_name)
    end
    
    it "should find all exercise names" do
      @repo.copy_simple_exercise('Ex1')
      @repo.copy_simple_exercise('Ex2')
      @repo.add_commit_push
      
      exercise_names = Exercise.read_exercise_names(@course_name)
      exercise_names.length.should == 2
      
      exercise_names.sort!
      exercise_names[0].should == 'Ex1'
      exercise_names[1].should == 'Ex2'
    end
    
    # TODO: should test metadata loading, but tests for Course.refresh already test that.
    # Some more mocking should probably happen somewhere..
    
  end
  
  
  describe "associated submissions" do
    before :each do
      @exercise = Exercise.create!(:course => course, :name => 'MyExercise')
      @submission_attrs = {
        :course => course,
        :exercise_name => 'MyExercise',
        :user => user,
        :skip_test_runner => true
      }
      Submission.create!(@submission_attrs)
      Submission.create!(@submission_attrs)
      @submissions = Submission.all
    end
    
    it "should be associated by exercise name" do
      @exercise.submissions.size.should == 2
      @submissions[0].exercise.should == @exercise
      @submissions[0].exercise_name = 'AnotherExercise'
      @submissions[0].save!
      @exercise.submissions.size.should == 1
    end
  end
  
  it "can tell whether a user has ever attempted an exercise" do
    exercise = Exercise.new(:course => course, :name => 'MyExercise')
    exercise.should_not be_attempted_by(user)
    
    Submission.create!(:user => user, :course => course, :exercise_name => exercise.name)
    exercise.should be_attempted_by(user)
  end
  
  it "can tell whether a user has completed an exercise" do
    exercise = Exercise.new(:course => course, :name => 'MyExercise')
    exercise.should_not be_completed_by(user)
    
    other_user = Factory.create(:user)
    other_user_sub = Submission.create!(:user => other_user, :course => course, :exercise_name => exercise.name)
    other_user_sub.test_case_runs.create!(:test_case_name => 'one', :successful => true)
    other_user_sub.test_case_runs.create!(:test_case_name => 'two', :successful => true)
    exercise.should_not be_completed_by(user)
    
    Submission.create!(:user => user, :course => course, :exercise_name => exercise.name, :pretest_error => 'oops')
    exercise.should_not be_completed_by(user)
    
    sub = Submission.create!(:user => user, :course => course, :exercise_name => exercise.name)
    tcr1 = sub.test_case_runs.create!(:test_case_name => 'one', :successful => true)
    tcr2 = sub.test_case_runs.create!(:test_case_name => 'one', :successful => false)
    exercise.should_not be_completed_by(user)

    tcr2.successful = true
    tcr2.save!
    exercise.should be_completed_by(user)
  end
end

