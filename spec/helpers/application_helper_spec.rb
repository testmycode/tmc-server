require 'spec_helper'

describe ApplicationHelper do
  def h(*args) # Hack to make 'h' accessible to the helper being tested (Worked in Rails 3.0, found broken on upgrade to 3.1.1)
    helper.send('h', *args)
  end
  
  describe "#breadcrumb" do # Not a complete specification
    it "should show the current course" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @controller_name = 'unknown_controller'
      @action_name = 'unknown_action'
      breadcrumb.should include('MyCourse')
    end
    
    it "should show the current exercise and its course" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @exercise = mock_model(Exercise, :name => 'MyExercise', :course => @course, :new_record? => false)
      breadcrumb.should include('MyCourse')
      breadcrumb.should include('MyExercise')
    end
    
    it "should show the current submission, its course and its exercise" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @exercise = mock_model(Exercise, :name => 'MyExercise', :course => @course, :new_record? => false)
      @submission = mock_model(Submission, :id => 123, :course => @course, :exercise => @exercise, :new_record? => false)
      breadcrumb.should include('MyCourse')
      breadcrumb.should include('MyExercise')
      breadcrumb.should include('Submission')
      breadcrumb.should include('#123')
    end
    
    it "should show the current submission, its course and its exercise name even if the exercise was deleted" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @submission = mock_model(Submission, :id => 123, :course => @course, :exercise_name => 'MyExercise', :new_record? => false)
      breadcrumb.should include('MyCourse')
      breadcrumb.should include('deleted exercise')
      breadcrumb.should include('MyExercise')
      breadcrumb.should include('Submission')
      breadcrumb.should include('#123')
    end
  end
end
