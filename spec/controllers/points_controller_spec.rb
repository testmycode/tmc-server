# encoding: UTF-8
require 'spec_helper'

describe PointsController, type: :controller do
  render_views
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    @sheetname = 'testsheet'
    @exercise = FactoryGirl.create(:exercise, course: @course,
                                              gdocs_sheet: @sheetname)
    @admin = FactoryGirl.create(:admin)
  end

  describe 'GET show' do
    describe 'when user has participated in a course' do
      before :each do
        controller.current_user = @admin
        @user = FactoryGirl.create(:user)
        @submission = FactoryGirl.create(:submission,
                                         course: @course,
                                         user: @user,
                                         exercise: @exercise)
        @available_point = FactoryGirl.create(:available_point,
                                              exercise: @exercise)

        @awarded_point = FactoryGirl.create(:awarded_point,
                                            course: @course,
                                            name: @available_point.name,
                                            submission: @submission,
                                            user: @user)
      end

      it 'should show a page' do
        get :show, organization_id: @organization.slug,
            course_name: @course.name, id: @sheetname
        expect(response).to be_success
      end

      it 'should contain @user login' do
        get :show, organization_id: @organization.slug, course_name: @course.name, id: @sheetname
        expect(response.body).to have_content(@user.login)
      end

      it 'should contain available point name' do
        get :show, organization_id: @organization.slug, course_name: @course.name, id: @sheetname
        expect(response.body).to have_content(@available_point.name)
      end

      it 'should contain a success marker' do
        get :show, organization_id: @organization.slug, course_name: @course.name, id: @sheetname
        expect(response.body).to have_content('✔')
      end
    end
  end
end
