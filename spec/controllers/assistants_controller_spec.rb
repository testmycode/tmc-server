require 'spec_helper'

describe AssistantsController, type: :controller do
  before :each do
    @user = FactoryGirl.create(:user)
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create :course, organization: @organization
    @teacher = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
  end

  describe 'As a teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET index' do
      it 'lists assistants in course' do
        user1 = FactoryGirl.create(:user)
        user2 = FactoryGirl.create(:user)
        user3 = FactoryGirl.create(:user)
        @course.assistants << [user1, user2, user3]
        get :index, organization_id: @organization.slug, course_name: @course.name
        expect(assigns(:assistants)).to eq([user1, user2, user3])
      end
    end

    describe 'POST create' do
      it 'with a valid username adds a new assistant' do
        expect do
          post :create, organization_id: @organization.slug, course_name: @course.name, username: @user.username
        end.to change(Assistantship, :count).by(1)
      end

      it 'with a invalid username doesn\'t add any assistants' do
        expect do
          post :create, organization_id: @organization.slug, course_name: @course.name, username: 'invalid'
        end.to change(Assistantship, :count).by(0)
      end

      it 'with a username that already is an assistant for course, donesn\'t add' do
        Assistantship.create! user: @user, course: @course
        expect do
          post :create, organization_id: @organization.slug, course_name: @course.name, username: @user.username
        end.to change(Assistantship, :count).by(0)
      end
    end

    describe 'DELETE destroy' do
      it 'removes assistant' do
        @assistantship = Assistantship.create! user: @user, course: @course
        expect do
          delete :destroy, organization_id: @organization.slug, course_name: @course.name, id: @assistantship.to_param
        end.to change(Assistantship, :count).by(-1)
      end
    end
  end

  describe 'As a user' do
    before :each do
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'denies access' do
        get :index, organization_id: @organization.slug, course_name: @course.name
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST create' do
      it 'denies access' do
        post :create, organization_id: @organization.slug, course_name: @course.name, username: @user.username
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'DELETE destroy' do
      it 'denies access' do
        @assistantship = Assistantship.create! user: @user, course: @course
        delete :destroy, organization_id: @organization.slug, course_name: @course.name, id: @assistantship.to_param
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
