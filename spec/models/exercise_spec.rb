require 'spec_helper'

describe Exercise do
  include GitTestActions

  describe "when read from a course repo" do
    before :each do
      @course_name = 'MyCourse'
      FileUtils.mkdir_p 'bare_repo'
      copy_model_repo("bare_repo/#{@course_name}")
      system! "git clone -q bare_repo/#{@course_name} #{@course_name}"
      @repo = GitRepo.new("#{@course_name}")
    end
    
    it "should find all exercises" do
      @repo.copy_simple_exercise('Ex1')
      @repo.copy_simple_exercise('Ex2')
      @repo.add_commit_push
      
      exercises = Exercise.read_exercises(@course_name)
      exercises.length.should == 2
      
      exercises.sort_by &:name
      exercises[0].name.should == 'Ex1'
      exercises[1].name.should == 'Ex2'
    end
    
    it "should produce a valid exercise object when plugged into a course" do
      @repo.copy_simple_exercise('Exercise')
      @repo.add_commit_push
      
      exercise = Exercise.read_exercises(@course_name)[0]
      
      exercise.should be_valid
    end
    
    # TODO: should test metadata loading, but tests for Course.refresh already test that.
    # Some more mocking should probably happen somewhere..
    
  end
  
  
  describe "associated submissions" do
    before :each do
      # FactoryGirl would be useful here. Probably elsewhere too.
      @course = Course.create!(:name => 'MyCourse')
      @exercise = Exercise.create!(:course => @course, :name => 'MyExercise')
      @user = User.create!(:login => 'JohnShepard')
      @submission_attrs = {
        :course => @course,
        :exercise_name => 'MyExercise',
        :user => @user,
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
end

