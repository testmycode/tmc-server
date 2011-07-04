#Tests have been written with name as id. Name and id will / should be separated later on?

#Should courses be sorted somehow sometimes? Like alphabethical order? 

require 'spec_helper'

describe CoursesController do

  before(:each) do
    @testCourses = Course.create!(:name => 'TestCourse')
  end
  
  #this method destroys also the repository, not only rspec db
  after(:each) do
    @testCourses.destroy
  end

# This should return the minimal set of attributes required to create a valid
  # Course. As you add validations to Course, be sure to
  # update the return value of this method accordingly.
  
  #def valid_attributes
    #{:name => 'rspecCourse2'}
  #end 
  
  describe "GET index" do
    it "assigns @courses in order by name" do 
      get :index
      assigns(:courses).should eq(Course.order("LOWER(name)"))
    end
  end
  
  describe "GET show" do
    it "assigns the requested course as @testCourses" do 
      get :show, :id => @testCourses.name
      assigns(:course).should eq(@testCourses)
    end
  end
  
  describe "POST create" do
   
    describe "with valid parameters" do
      after(:each) do
        Course.find_by_name('newCourse').destroy
      end
      
      it "creates a new course to @testCourses" do 
        post :create, :course => { :name => 'newCourse' }
        assigns(:course).name.should eq(Course.new(:name => 'newCourse').name)
      end

      it "redirects to the created course" do 
        post :create, :course => { :name => 'newCourse' }
        response.should redirect_to(Course.last)
      end
    end
    
    describe "with invalid parameters" do
      it "should not create course with wrong name" do 
        post :create, :course => { :name => 'new Course' }
        Course.find_by_name('new Course').should be_false
      end
      
      it "should not create course without a name" do 
        expect {
          post :create, :course => {}
        }.to change(Course, :count).by(0) 
      end
      
      it "re-renders the 'new' template" do 
        post :create, :course => {}
        response.should render_template("new")
      end
    end
    
  end
  
  describe "DELETE course" do
    it "destroy a course from @testCourses by name" do
      delete :destroy, :id => @testCourses.name
      Course.find_by_id("TestCourse").should be_nil
    end
    
    it "re-renders the 'new' template" do 
      delete :destroy, :id => @testCourses.name
      response.should redirect_to(courses_url)
    end    
  end 
  
=begin
  describe "POST create" do
    describe "with valid params" do
      it "creates a new Course" do 
        expect {
          post :create, :course => valid_attributes #virhe: repository already exists
        }.to change(Course, :count).by(1)           
      end

      it "assigns a newly created course as @course" do 
        post :create, :course => valid_attributes #virhe: repository already exists
        assigns(:course).should be_a(Course)
        assigns(:course).should be_persisted
      end

      it "redirects to the created course" do 
        post :create, :course => valid_attributes #virhe: repository already exists
        response.should redirect_to(Course.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved course as @course" do
        # Trigger the behavior that occurs when invalid params are submitted
        Course.any_instance.stub(:save).and_return(false)
        post :create, :course => {}
        assigns(:course).should be_a_new(Course)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Course.any_instance.stub(:save).and_return(false)
        post :create, :course => {}
        response.should render_template("new")
      end
    end
  end

=end
end


