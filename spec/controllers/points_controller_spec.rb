# encoding: UTF-8
require 'spec_helper'

describe PointsController, :type => :controller do
  render_views
  before :each do
    @course = Factory.create(:course)
    @sheetname = "testsheet"
    @exercise = Factory.create(:exercise, :course => @course,
                               :gdocs_sheet => @sheetname)
    @admin = Factory.create(:admin)
  end

  describe "GET show" do
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
        expect(response).to be_success
      end

      it "should contain @user login" do
        get :show, :course_id => @course.id, :id => @sheetname
        expect(response.body).to have_content(@user.login)
      end

      it "should contain available point name" do
        get :show, :course_id => @course.id, :id => @sheetname
        expect(response.body).to have_content(@available_point.name)
      end

      it "should contain a success marker" do
        get :show, :course_id => @course.id, :id => @sheetname
        expect(response.body).to have_content("✔")
      end
    end
  end
end

