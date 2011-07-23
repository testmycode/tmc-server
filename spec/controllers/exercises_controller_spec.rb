require 'spec_helper'

describe ExercisesController do

  before(:each) do
    @course = Course.new(:name => 'MyCourse')
    @course.exercises << Exercise.new(:name => 'Exercise1', :course => @course)
    @course.exercises << Exercise.new(:name => 'Exercise2', :course => @course)
    @course.stub(:id => 1)
    @course.exercises[0].stub(:id => 1)
    @course.exercises[1].stub(:id => 2)
    Course.stub(:find).with('1').and_return(@course)
  end
  
  describe "GET index" do
    describe "in JSON format" do
      it "should render the courses in JSON" do
        get :index, :course_id => '1', :format => 'json'
        result = JSON.parse(response.body)
        result.should be_a(Array)
        result[0]['name'].should == 'Exercise1'
        result[1]['name'].should == 'Exercise2'
        result[0]['zip_url'].should == course_exercise_url(1, 1, :format => 'zip')
        result[0]['return_address'].should == course_exercise_submissions_url(1, 1)
      end
    end
  end

end
