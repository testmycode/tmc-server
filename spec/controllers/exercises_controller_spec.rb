require 'spec_helper'

#Exercises_controller new, update, delete and edit may not be needed. If so, no need to test.

describe ExercisesController do

  before :each do
    @c = Course.create!(:name => "TestCourse")
  end
  
  describe "GET index" do
    it "assigns all exercises as @exercises" do
      e = Exercise.create! :name => "test", :course_id => @c.id
      get :index, :course_id => @c.id
      assigns(:exercises).should == [e]
    end
  end
end
