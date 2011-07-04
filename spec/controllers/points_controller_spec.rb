require 'spec_helper'

describe PointsController do

  def valid_attributes
    { :exercise_number => "2.3", 
      :tests_pass => true,
      :exercise_point_id => 1,
      :student_id => "123",
      :course_id => 1 }
  end

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET index" do
    it "assigns all points as @points_status" do
      p = Point.create! valid_attributes
      get :index
      assigns(:points_status).should == Point.all
    end

    it "should be alphabetically sorted, by created_at descending, last 50" do
      p1 = Point.create! :exercise_number => "2.3", :tests_pass => true,
        :student_id => "stud_id", :course_id => 1, :exercise_point_id => 1
      p2 = Point.create! :exercise_number => "2.3", :tests_pass => true,
        :student_id => "a", :course_id => 1, :exercise_point_id => 1
      p3 = Point.create! :exercise_number => "2.3", :tests_pass => true,
        :student_id => "z", :course_id => 1, :exercise_point_id => 1
      get :index
      assigns(:points_status).should == Point.order("(created_at)DESC LIMIT 50")
    end
  end

  it "should return a json string of points (alphabetically)" do
    p1 = Point.create! :exercise_number => "2.3", :tests_pass => true,
      :student_id => "stud_id", :course_id => 1, :exercise_point_id => 1
    p2 = Point.create! :exercise_number => "2.3", :tests_pass => true,
      :student_id => "a", :course_id => 1, :exercise_point_id => 1

    get :index, :format => :json
    response.body.should == [p2, p1].to_json
  end

end

