require 'spec_helper'

#Exercises_controller new, update, delete and edit may not be needed. If so, no need to test.

describe ExercisesController do

  before :all do
    @c = Course.create!(:name => "test_repo_5")
  end

  after :all do
    @c.destroy
  end

  describe "GET index" do
    it "assigns all exercises as @exercises" do
      e = Exercise.create! :name => "test", :course_id => @c.id
      get :index, :course_id => @c.name
      assigns(:exercises).should == [e]
    end
  end

  describe "GET show" do

    before :all do
      @e1 = Exercise.create! :name => "e1"
      @e2 = Exercise.create! :name => "e2"
    end
    
    after :all do
      @e1.destroy
      @e2.destroy
    end

=begin #oldoldoldold tests. doesn't work at all
    it "finds the first exercise by id" do
      get :show, :id => @e1.name, :course_id => @c.name
      assigns(:exercise).should == @e1
    end

    it "finds the second exercise by id" do
      get :show, :id => @e2.name, :course_id => @c.name
      assigns(:exercise).should == @e2
    end
    
    it "renders the exercise template for 'e1'" do
      get :show, :id => @e1.name, :course_id => @c.name
      response.should render_template("show")
    end
=end
  end
  
  describe "private get_course at exercises set" do
  
    it "valid parameter finds course for the exercises" do
      @controller.params = {:course_id => @c.name}
      course = @controller.send(:get_course)
      course.should eq(@c)
    end

    # Doesn't work at all (not sure if this is the right way to handle this anyway
    it "invalid parameter doesn't find course for the exercises" do
      pending "add some examples to (or delete) #{__FILE__}"
=begin
      @controller.params = {}
      expect {
        @controller.send(:get_course)
      }.to raise_error(RuntimeError)
=end
    end
  end
end
