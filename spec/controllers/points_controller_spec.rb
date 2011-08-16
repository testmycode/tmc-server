require 'spec_helper'

describe PointsController do
  render_views
  before :each do
    @course = Factory.create(:course)
    @sheetname = "testsheet"
    @exercise = Factory.create(:exercise, :course => @course,
                               :gdocs_sheet => @sheetname)
    @admin = Factory.create(:admin)
  end

  describe "GET show" do
    describe "when guest visits" do
      it "should not allow access" do
        expect {
          get :show, :course_id => @course.id.to_s, :id => @sheetname
        }.to raise_error(CanCan::AccessDenied)
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
        get :show, :course_id => @course.id, :id => @sheetname
        response.should be_success
      end

      it "should contain @user login" do
        get :show, :course_id => @course.id, :id => @sheetname
        response.body.should have_content(@user.login)
      end

      it "should contain available point name" do
        get :show, :course_id => @course.id, :id => @sheetname
        response.body.should have_content(@available_point.name)
      end

      it "should contain a success marker" do
        get :show, :course_id => @course.id, :id => @sheetname
        response.body.should have_content("✔")
      end
    end
  end
end

