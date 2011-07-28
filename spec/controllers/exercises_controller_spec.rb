require 'spec_helper'

describe ExercisesController do

  before(:each) do
    @course = Factory.create(:course)
    @course.exercises << Factory.create(:exercise, :name => 'Exercise1', :course => @course)
    @course.exercises << Factory.create(:exercise, :name => 'Exercise2', :course => @course)
  end
  
  describe "GET index" do
    describe "in JSON format" do
    
      def get_index_json(options = {})
        options = {
          :course_id => @course.id.to_s,
          :format => 'json'
        }.merge options
        get :index, options
        JSON.parse(response.body)
      end
    
      it "should render the courses in JSON" do
        result = get_index_json
        result.should be_a(Array)
        result[0]['name'].should == 'Exercise1'
        result[1]['name'].should == 'Exercise2'
        result[0]['zip_url'].should == course_exercise_url(1, 1, :format => 'zip')
        result[0]['return_address'].should == course_exercise_submissions_url(1, 1, :format => 'json')
      end
      
      describe "when given a username parameter" do
        before :each do
          @user = Factory.create(:user)
        end
        
        it "should tell for each exercise whether it has been attempted" do
          sub = Factory.create(:submission, :course => @course, :exercise => @course.exercises[0], :user => @user)
          Factory.create(:test_case_run, :submission => sub, :successful => false)
          
          result = get_index_json :username => @user.login
          
          result[0]['attempted'].should be_true
          result[1]['attempted'].should be_false
        end
        
        it "should tell for each exercise whether it has been completed" do
          sub = Factory.create(:submission, :course => @course, :exercise => @course.exercises[0], :user => @user)
          Factory.create(:test_case_run, :submission => sub, :successful => true)
          
          result = get_index_json :username => @user.login
          
          result[0]['completed'].should be_true
          result[1]['completed'].should be_false
        end
      end
    end
  end

end
