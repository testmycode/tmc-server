require 'spec_helper'

describe CoursesController do

  before(:each) do
    session[:user_id] = User.create!(:login => 'testuser', :password => 'testpassword').id
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
        @course.exercises << Factory.create(:exercise, :name => 'Exercise1', :course => @course)
        @course.exercises << Factory.create(:exercise, :name => 'Exercise2', :course => @course)
      end
    
      def get_index_json(options = {})
        options = { :format => 'json' }.merge options
        get :index, options
        JSON.parse(response.body)
      end
    
      it "renders all non-hidden courses in order by name" do
        Factory.create(:course, :name => 'Course2', :hide_after => Time.now + 1.week)
        Factory.create(:course, :name => 'Course3')
        Factory.create(:course, :name => 'HiddenCourse', :hide_after => Time.now - 1.week)
        
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
        
        describe "and the user does not exist" do
          before :each do
            @user.destroy
          end
          
          it "should behave as if the username parameter was not given" do
            result = get_index_json :username => @user.login
          
            exs = result[0]['exercises']
            exs[0]['name'].should == 'Exercise1'
            exs[0]['attempted'].should be_nil
          end
        end
      end
      
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
end


