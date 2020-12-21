# frozen_string_literal: true

require 'spec_helper'

describe Setup::CourseAssistantsController, type: :controller do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    @assistant = FactoryGirl.create(:user, login: 'assi')
    Teachership.create!(user: @teacher, organization: @organization)
  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET index' do
      it 'lists assistants in course' do
        user1 = FactoryGirl.create(:user)
        user2 = FactoryGirl.create(:user)
        user3 = FactoryGirl.create(:user)
        @course.assistants << [user1, user2, user3]
        get :index, params: { organization_id: @organization.slug, course_id: @course.id }
        expect(assigns(:assistants)).to eq([user1, user2, user3])
      end
    end

    describe 'post CREATE' do
      it 'creates a new assistant' do
        expect(@course.assistants.count).to eq(0)
        post :create, params: {
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Add new assistant',
             username: 'assi',
             email: @assistant.email
        }
        expect(assigns(:course).assistants.first).to eq(@assistant)
        expect(Assistantship.count).to be(1)
      end

      it 'does not create assistant if user not found' do
        expect(@course.assistants.count).to eq(0)
        post :create, params: {
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Add new assistant',
             username: 'notfound',
             email: 'assi@absintti.org'
        }
        expect(@course.assistants.count).to eq(0)
        expect(response).to render_template(:index)
      end

      it 'does not create assistant if user is already assistant' do
        @course.assistants << @assistant
        expect(@course.assistants.count).to eq(1)
        post :create, params: {
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Add new assistant',
             username: 'assi',
             email: @assistant.email 
        }
        expect(@course.assistants.count).to eq(1)
        expect(response).to render_template(:index)
      end

      it 'continues to next step when in wizard mode' do
        post :create, params: { organization_id: @organization.slug, course_id: @course.id, commit: 'Continue' }
        expect(response).to redirect_to(setup_organization_course_course_finisher_index_path)
      end

      it 'continues to course main page when not in wizard' do
        post :create, params: { organization_id: @organization.slug, course_id: @course.id, commit: 'Bach to course main page' }
        expect(response).to redirect_to(organization_course_path(@organization, @course))
      end
    end

    describe 'DELETE destroy' do
      it 'removes assistant' do
        @assistantship = Assistantship.create! user: @user, course: @course
        expect(@course.assistants.count).to eq(1)
        expect do
          delete :destroy, params: { organization_id: @organization.slug, course_id: @course.id, id: @assistantship.to_param }
        end.to change(Assistantship, :count).by(-1)
      end
    end
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    it 'should not allow any access' do
      get :index, params: { organization_id: @organization.slug, course_id: @course.id }
      expect(response.code.to_i).to eq(403)
      post :create, params: {
           organization_id: @organization.slug,
           course_id: @course.id,
           commit: 'Add new assistant',
           username: 'assi'
      }
      expect(response.code.to_i).to eq(403)
      @assistantship = Assistantship.create! user: @user, course: @course
      delete :destroy, params: { organization_id: @organization.slug, course_id: @course.id, id: @assistantship.to_param }
      expect(response.code.to_i).to eq(302)
    end
  end
end
