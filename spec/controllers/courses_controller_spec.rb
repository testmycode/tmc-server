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
    
    describe "as json" do
      it "renders all courses in order by name" do
        get :index, :format => 'json'
        result = JSON.parse(response.body)
        result.should be_a(Array)
        result[0]['name'].should == 'AnotherTestCourse'
        result[1]['name'].should == 'ExpiredCourse'
        result[0]['hide_after'].should be_nil
        result[1]['hide_after'].should_not be_nil
        result[0]['exercises_json'].should == course_exercises_url(@courses[2], :format => 'json')
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


