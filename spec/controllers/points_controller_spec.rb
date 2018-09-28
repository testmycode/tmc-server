
# frozen_string_literal: true

require 'spec_helper'

describe PointsController, type: :controller do
  render_views

  before :each do
    @user = FactoryGirl.create(:user)
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create :course, organization: @organization
    @sheetname = 'testsheet'
    @exercise = FactoryGirl.create(:exercise, course: @course, gdocs_sheet: @sheetname)
    @submission = FactoryGirl.create(:submission,
                                     course: @course,
                                     user: @user,
                                     exercise: @exercise)
    @available_point = FactoryGirl.create(:available_point, exercise: @exercise)
    @awarded_point = FactoryGirl.create(:awarded_point,
                                        course: @course,
                                        name: @available_point.name,
                                        submission: @submission,
                                        user: @user)
    controller.current_user = @user
  end

  describe 'GET index' do
    describe 'when user has participated in a course' do
      it 'should show a page' do
        get :index, organization_id: @organization.slug, course_id: @course.id
        expect(response).to be_success
      end

      it 'should not show a page when submission result are hidden' do
        @course.hide_submission_results = true
        @course.save!
        get :index, organization_id: @organization.slug, course_id: @course.id
        expect(response.code.to_i).to eq(401)
      end
    end
  end

  describe 'GET show' do
    describe 'when user has participated in a course' do
      it 'should show a page' do
        get :show, organization_id: @organization.slug,
                   course_id: @course.id, id: @sheetname
        expect(response).to be_success
      end

      it 'should contain @user login' do
        get :show, organization_id: @organization.slug, course_id: @course.id, id: @sheetname
        expect(response.body).to have_content(@user.login)
      end

      it 'should contain available point name' do
        get :show, organization_id: @organization.slug, course_id: @course.id, id: @sheetname
        expect(response.body).to have_content(@available_point.name)
      end

      it 'should contain a success marker' do
        get :show, organization_id: @organization.slug, course_id: @course.id, id: @sheetname
        expect(response.body).to have_content('✔')
      end

      it 'should not show a page when submission result are hidden' do
        @course.hide_submission_results = true
        @course.save!
        get :show, organization_id: @organization.slug, course_id: @course.id, id: @sheetname
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
