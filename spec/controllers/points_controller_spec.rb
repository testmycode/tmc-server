# typed: false

# frozen_string_literal: true

require 'spec_helper'

describe PointsController, type: :controller do
  render_views

  before :each do
    @user = FactoryBot.create(:user)
    @organization = FactoryBot.create(:accepted_organization)
    @course = FactoryBot.create :course, organization: @organization
    @sheetname = 'testsheet'
    @exercise = FactoryBot.create(:exercise, course: @course, gdocs_sheet: @sheetname)
    @submission = FactoryBot.create(:submission,
                                     course: @course,
                                     user: @user,
                                     exercise: @exercise)
    @available_point = FactoryBot.create(:available_point, exercise: @exercise)
    @awarded_point = FactoryBot.create(:awarded_point,
                                        course: @course,
                                        name: @available_point.name,
                                        submission: @submission,
                                        user: @user)
    controller.current_user = @user
  end

  describe 'GET index' do
    describe 'when user has participated in a course' do
      it 'should show a page' do
        get :index, params: { organization_id: @organization.slug, course_id: @course.id }
        expect(response).to be_successful
      end

      it 'should not show a page when submission result are hidden' do
        @course.hide_submission_results = true
        @course.save!
        get :index, params: { organization_id: @organization.slug, course_id: @course.id }
        expect(response.code.to_i).to eq(403)
      end
    end
  end

  describe 'GET show' do
    describe 'when user has participated in a course' do
      it 'should show a page' do
        get :show, params: { organization_id: @organization.slug,
                   course_id: @course.id, id: @sheetname }
        expect(response).to be_successful
      end

      it 'should contain @user login' do
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @sheetname }
        expect(response.body).to have_content(@user.login)
      end

      it 'should contain available point name' do
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @sheetname }
        expect(response.body).to have_content(@available_point.name)
      end

      it 'should contain a success marker' do
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @sheetname }
        expect(response.body).to have_content('✔')
      end

      it 'should not show a page when submission result are hidden' do
        @course.hide_submission_results = true
        @course.save!
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @sheetname }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'in JSON format' do
      before :each do
        @other_user = FactoryBot.create(:user)
        other_submission = FactoryBot.create(:submission, course: @course, user: @other_user, exercise: @exercise)
        FactoryBot.create(:awarded_point, course: @course, name: @available_point.name, submission: other_submission, user: @other_user)
      end

      it 'gives a student only their own points' do
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @sheetname, format: :json, api_version: ApiVersion::API_VERSION }
        expect(response.parsed_body['users_to_points'].keys).to eq([@user.login])
      end

      it "gives a teacher everyone's points" do
        teacher = FactoryBot.create(:user)
        Teachership.create!(user: teacher, organization: @organization)
        controller.current_user = teacher
        get :show, params: { organization_id: @organization.slug, course_id: @course.id, id: @sheetname, format: :json, api_version: ApiVersion::API_VERSION }
        expect(response.parsed_body['users_to_points'].keys).to contain_exactly(@user.login, @other_user.login)
      end
    end
  end
end
