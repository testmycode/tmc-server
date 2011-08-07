require 'spec_helper'

describe PointsController do
  render_views
  before :each do
    @course = Factory.create(:course)
    @exercise = Factory.create(:exercise, :course => @course)
    @admin = Factory.create(:admin)
  end

  describe "GET index" do
    describe "when guest visits" do
      it "should not allow access" do
        expect { get :index, :course_id => @course.id.to_s }.to
          raise_error(CanCan::AccessDenied)
      end
    end

    describe "when user has participated in a course" do
      before :each do
        controller.current_user = @admin
        @user = Factory.create(:user)
        @submission = Factory.create(:submission,
                                     :course => @course,
                                     :user => @user,
                                     :exercise => @exercise)
        @available_point = Factory.create(:available_point,
                                         :exercise => @exercise)

        @awarded_point = Factory.create(:awarded_point,
                                        :course => @course,
                                        :name => @available_point.name,
                                        :submission => @submission,
                                        :user => @user)
      end

      it "should show a page" do
        get :index, :course_id => @course.id
        response.should be_success
      end

      it "should contain @user login" do
        get :index, :course_id => @course.id
        response.body.should have_content(@user.login)
      end

      it "should contain available point name" do
        get :index, :course_id => @course.id
        response.body.should have_content(@available_point.name)
      end

      it "should contain a success marker" do
        get :index, :course_id => @course.id
        response.body.should have_content("✔")
      end
    end
  end
end

