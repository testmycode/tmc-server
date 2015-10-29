require 'spec_helper'

describe EmailsController, type: :controller do
  before(:each) do
    @admin = FactoryGirl.create(:admin)
    @user = FactoryGirl.create(:user)
    @teacher = FactoryGirl.create(:user)
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    Teachership.create(user: @teacher, organization: @organization)
  end

  describe 'GET index' do
    describe 'global list' do
      it 'lists all users in the system if current user is admin' do
        controller.current_user = @admin
        get :index, format: :text
        User.all.each do |user|
          expect(assigns(:emails)).to include(user.email)
        end
      end

      it 'denies access for non-admins' do
        controller.current_user = @teacher
        get :index, format: :text
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'course list' do
      before :each do
        @ex1 = @course.exercises.create(name: 'e1')
        @ex2 = @course.exercises.create(name: 'e2')

        @user1 = FactoryGirl.create(:user)
        @user2 = FactoryGirl.create(:user)
        @user3 = FactoryGirl.create(:user)

        sub1 = FactoryGirl.create(:submission, course: @course, user: @user1, exercise: @ex1)
        sub2 = FactoryGirl.create(:submission, course: @course, user: @user1, exercise: @ex2)
        sub3 = FactoryGirl.create(:submission, course: @course, user: @user2, exercise: @ex2)

        FactoryGirl.create(:awarded_point, course: @course, submission: sub1, user: @user1)
        FactoryGirl.create(:awarded_point, course: @course, submission: sub2, user: @user1)
        FactoryGirl.create(:awarded_point, course: @course, submission: sub3, user: @user2)
      end

      it 'assigns users in @students array if they have submitted exercises to the course if current user is teacher' do
        controller.current_user = @teacher
        get :index, organization_id: @organization.slug, name: @course.name
        expect(assigns(:students)).to include(@user1)
        expect(assigns(:students)).to include(@user2)
        expect(assigns(:students)).to_not include(@user3)
      end

      it 'denies access for non-teachers' do
        controller.current_user = @user
        get :index, organization_id: @organization.slug, name: @course.name
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
