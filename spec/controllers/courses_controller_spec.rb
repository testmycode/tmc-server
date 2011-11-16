require 'spec_helper'

describe CoursesController do

  before(:each) do
    @user = Factory.create(:user)
    controller.current_user = @user
  end
  
  describe "GET index" do
    it "shows courses in order by name, split into ongoing and expired" do 
      @courses = [
        Factory.create(:course, :name => 'SomeTestCourse'),
        Factory.create(:course, :name => 'ExpiredCourse', :hide_after => Time.now - 1.week),
        Factory.create(:course, :name => 'AnotherTestCourse')
      ]
      
      get :index
      
      assigns(:ongoing_courses).map(&:name).should == ['AnotherTestCourse', 'SomeTestCourse']
      assigns(:expired_courses).map(&:name).should == ['ExpiredCourse']
    end
    
    describe "in JSON format" do
      before :each do
        @course = Factory.create(:course, :name => 'Course1')
        @course.exercises << Factory.create(:returnable_exercise, :name => 'Exercise1', :course => @course)
        @course.exercises << Factory.create(:returnable_exercise, :name => 'Exercise2', :course => @course)
        @course.exercises << Factory.create(:returnable_exercise, :name => 'Exercise3', :course => @course)
      end
      
      def get_index_json(options = {})
        options = {
          :format => 'json',
          :username => @user.login
        }.merge options
        get :index, options
        JSON.parse(response.body)
      end
      
      it "renders all non-hidden courses in order by name" do
        Factory.create(:course, :name => 'Course2', :hide_after => Time.now + 1.week)
        Factory.create(:course, :name => 'Course3')
        Factory.create(:course, :name => 'ExpiredCourse', :hide_after => Time.now - 1.week)
        Factory.create(:course, :name => 'HiddenCourse', :hidden => true)
        
        result = get_index_json
        
        result.map {|c| c['name'] }.should == ['Course1', 'Course2', 'Course3']
      end
      
      it "should render the exercises for each course" do
        result = get_index_json
        
        exs = result[0]['exercises']
        exs[0]['name'].should == 'Exercise1'
        exs[1]['name'].should == 'Exercise2'
        exs[0]['zip_url'].should == course_exercise_url(@course.id, @course.exercises[0].id, :format => 'zip')
        exs[0]['return_address'].should == course_exercise_submissions_url(@course.id, @course.exercises[0].id, :format => 'json')
      end
      
      it "should include only submittable exercises for non-administrators" do
        @course.exercises[0].hidden = true
        @course.exercises[0].save!
        @course.exercises[1].deadline = Date.yesterday
        @course.exercises[1].save!
        
        result = get_index_json

        names = result[0]['exercises'].map {|ex| ex['name']}
        names.should_not include('Exercise1')
        names.should_not include('Exercise2')
        names.should include('Exercise3')
      end
      
      it "should tell for each exercise whether it has been attempted" do
        sub = Factory.create(:submission, :course => @course, :exercise => @course.exercises[0], :user => @user)
        Factory.create(:test_case_run, :submission => sub, :successful => false)
        
        result = get_index_json :username => @user.login
        
        exs = result[0]['exercises']
        exs[0]['attempted'].should be_true
        exs[1]['attempted'].should be_false
      end
      
      it "should tell for each exercise whether it has been completed" do
        sub = Factory.create(:submission, :course => @course, :exercise => @course.exercises[0], :user => @user)
        Factory.create(:test_case_run, :submission => sub, :successful => true)
        
        result = get_index_json :username => @user.login
        
        exs = result[0]['exercises']
        exs[0]['completed'].should be_true
        exs[1]['completed'].should be_false
      end
      
      describe "and the given username does not exist" do
        before :each do
          @user.destroy
        end
        
        it "should respond with a 403" do
          get :index, :format => :json, :username => @user.login
          response.code.to_i.should == 403
        end
      end
      
    end
  end
  
  
  describe "GET show" do
    before :each do
      @course = Factory.create(:course)
    end
  
    describe "for administrators" do
      before :each do
        @admin = Factory.create(:admin)
        controller.stub(:current_user => @admin)
      end
    
      it "should show everyone's submissions" do
        user1 = Factory.create(:user)
        user2 = Factory.create(:user)
        sub1 = Factory.create(:submission, :user => user1, :course => @course)
        sub2 = Factory.create(:submission, :user => user2, :course => @course)
        
        get :show, :id => @course.id
        
        assigns['submissions'].should include(sub1)
        assigns['submissions'].should include(sub2)
      end
    end
    
    describe "for guests" do
      before :each do
        controller.current_user = Guest.new
      end
      
      it "should show no submissions" do
        Factory.create(:submission, :course => @course)
        Factory.create(:submission, :course => @course)
        
        get :show, :id => @course.id
        
        assigns['submissions'].should be_nil
      end
    end
    
    describe "for regular users" do
      before :each do
        @user = Factory.create(:user)
        controller.stub(:current_user => @user)
      end
      
      it "should show only the current user's submissions" do
        other_user = Factory.create(:user)
        my_sub = Factory.create(:submission, :user => @user, :course => @course)
        other_guys_sub = Factory.create(:submission, :user => other_user, :course => @course)
        
        get :show, :id => @course.id
        
        assigns['submissions'].should include(my_sub)
        assigns['submissions'].should_not include(other_guys_sub)
      end
    end
  end
  
  
  describe "POST create" do
    
    before :each do
      controller.current_user = Factory.create(:admin)
    end
    
    describe "with valid parameters" do
      it "creates the course" do
        post :create, :course => { :name => 'NewCourse', :source_url => 'git@example.com' }
        Course.last.source_url.should == 'git@example.com'
      end
    
      it "redirects to the created course" do 
        post :create, :course => { :name => 'NewCourse', :source_url => 'git@example.com' }
        response.should redirect_to(Course.last)
      end
    end
    
    describe "with invalid parameters" do
      it "re-renders the course creation form" do 
        post :create, :course => { :name => 'invalid name with spaces' }
        response.should render_template("new")
        assigns(:course).name.should == 'invalid name with spaces'
      end
    end
  end
end


