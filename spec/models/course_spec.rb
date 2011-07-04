require 'spec_helper'

describe Course do

  it "can be created with just a name parameter" do
    Course.create!(:name => 'TestCourse')
  end

  it "should create a repository when created" do
    repo_path = Course.create!(:name => 'TestCourse').bare_path
    File.exists?(repo_path).should be_true
  end
  
  it "should delete the repository when destroyed" do
    course = Course.create!(:name => 'TestCourse')
    repo_path = course.bare_path
    course.destroy
    File.exists?(repo_path).should be_false
  end

  describe "validations" do
    it "requires a name" do
      should_be_invalid_params({})
    end

    it "requires name to be reasonably short" do
      should_be_invalid_params(:name => 'a'*41)
    end
    
    it "requires name to be non-unique" do
      Course.create!(:name => 'TestCourse')
      should_be_invalid_params(:name => 'TestCourse')
    end

    it "forbids spaces in the name" do # this could eventually be lifted as long as everything else is made to tolerate spaces
      should_be_invalid_params(:name => 'Test Course')
    end

    def should_be_invalid_params(params)
      expect { Course.create!(params) }.to raise_error
    end
  end
  
  describe "when refreshed" do
    include GitTestActions
    
    before :each do
      @course = Course.create!(:name => 'TestCourse')
      @repo = clone_course_repo(@course)
    end
    
    it "should discover new exercises" do
      add_exercise('MyExercise')
      @course.refresh
      @course.exercises.should have(1).items
      @course.exercises[0].name.should == 'MyExercise'
    end
    
    def add_exercise(name)
      ex = Exercise.new(:name => name)
      Exercise.stub(:read_exercises => [ex])
      @repo.copy_model_exercise(name)
      @repo.add_commit_push
    end
  end

end
