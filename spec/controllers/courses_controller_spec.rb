require 'spec_helper'

describe CoursesController do

  before(:each) do
    session[:user_id] = User.create!(:login => 'testuser', :password => 'testpassword').id
    @courses = [
      Course.create!(:name => 'SomeTestCourse'),
      Course.create!(:name => 'ExpiredCourse', :hide_after => Time.now - 1.week),
      Course.create!(:name => 'AnotherTestCourse')
    ]
  end
  
  describe "GET index" do
    it "shows courses in order by name, split into ongoing and expired" do 
      get :index
      assigns(:ongoing_courses).map(&:name).should == ['AnotherTestCourse', 'SomeTestCourse']
      assigns(:expired_courses).map(&:name).should == ['ExpiredCourse']
    end
    
    describe "in JSON format" do
      before :each do
        @courses.each &:destroy #FIXME!
        @course = Factory.create(:course, :name => 'Course1')
        @course.exercises << Factory.create(:exercise, :name => 'Exercise1', :course => @course)
        @course.exercises << Factory.create(:exercise, :name => 'Exercise2', :course => @course)
      end
    
      def get_index_json(options = {})
        options = { :format => 'json' }.merge options
        get :index, options
        JSON.parse(response.body)
      end
    
      it "renders all courses in order by name" do
        Factory.create(:course, :name => 'Course2', :hide_after => Time.now - 1.week)
        Factory.create(:course, :name => 'Course3')
        
        result = get_index_json
        
        result[0]['name'].should == 'Course1'
        result[1]['name'].should == 'Course2'
        result[2]['name'].should == 'Course3'
        result[0]['hide_after'].should be_nil
        result[1]['hide_after'].should_not be_nil
      end
    
      it "should render the exercises for each course" do
        result = get_index_json
        
        exs = result[0]['exercises']
        exs[0]['name'].should == 'Exercise1'
        exs[1]['name'].should == 'Exercise2'
        exs[0]['zip_url'].should == course_exercise_url(@course.id, @course.exercises[0].id, :format => 'zip')
        exs[0]['return_address'].should == course_exercise_submissions_url(@course.id, @course.exercises[0].id, :format => 'json')
      end
      
      describe "when given a username parameter" do
        before :each do
          @user = Factory.create(:user)
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
      end
      
    end
  end
  
  describe "GET show" do
    it "shows the requested course" do 
      get :show, :id => @courses[0].id
      assigns(:course).should == @courses[0]
    end
  end
  
  describe "POST create" do
   
    describe "with valid parameters" do
      it "creates the course with a local repo if no remote repo url is given" do
        post :create, :course => { :name => 'NewCourse' }
        Course.last.should have_local_repo
      end

      it "creates the course without a local repo if a remote repo url is given" do
        post :create, :course => { :name => 'NewCourse', :remote_repo_url => 'git@example.com' }
        Course.last.should have_remote_repo
        Course.last.bare_url.should == 'git@example.com'
      end
    
      it "redirects to the created course" do 
        post :create, :course => { :name => 'NewCourse' }
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
  
  describe "DELETE course" do
    it "destroys the given course" do
      delete :destroy, :id => @courses[0].id
      Course.find_by_id(@courses[0].id).should be_nil
    end
    
    it "redirects to the course list" do 
      delete :destroy, :id => @courses[0].id
      response.should redirect_to(courses_url)
    end    
  end 
end


