require 'spec_helper'

describe ExerciseStatusController do
  before :each do
    @course = Factory.create(:course)
    @exercise = Factory.create(:exercise, :course => @course)
    @exercise2 = Factory.create(:exercise, :course => @course)
  end

  describe "GET show" do
    describe "when user has participated in a course" do
      before :each do
        @user = Factory.create(:user)
        @submission = Factory.create(:submission,
                                     :course => @course,
                                     :user => @user,
                                     :exercise => @exercise,
                                     :all_tests_passed => true)
        @available_point = Factory.create(:available_point,
                                          :exercise => @exercise)

        @awarded_point = Factory.create(:awarded_point,
                                        :course => @course,
                                        :name => @available_point.name,
                                        :submission => @submission,
                                        :user => @user)

        @submission2 = Factory.create(:submission,
                                     :course => @course,
                                     :user => @user,
                                     :exercise => @exercise2,
                                     :all_tests_passed => false)
        @available_point2 = Factory.create(:available_point,
                                          :exercise => @exercise2)
        @available_point22 = Factory.create(:available_point,
                                          :exercise => @exercise2)

      end

      it "should show completition status for submitted exercises" do
        get :show, :course_id => @course.id, :id => @user.id
        response.should be_success
        json = JSON.parse response.body
        json.should have_key @exercise.name
        json.should have_key @exercise2.name
        json[@exercise.name].should == "completed"
        json[@exercise2.name].should == "started"
      end

      it "should work when using course and user name instrad of id:s" do
        get :show, :course_id => @course.name, :id => @user.login
        response.should be_success
        json = JSON.parse response.body
        json.should have_key @exercise.name
        json.should have_key @exercise2.name
        json[@exercise.name].should == "completed"
        json[@exercise2.name].should == "started"
      end
    end
  end
end
