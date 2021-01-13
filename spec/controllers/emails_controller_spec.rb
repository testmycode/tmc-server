# frozen_string_literal: true

require 'spec_helper'

describe EmailsController, type: :controller do
  before(:each) do
    @admin = FactoryBot.create(:admin)
    @user = FactoryBot.create(:user)
    @teacher = FactoryBot.create(:user)
    @organization = FactoryBot.create(:accepted_organization)
    @course = FactoryBot.create(:course, organization: @organization)
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
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'course list' do
      before :each do
        @ex1 = @course.exercises.create(name: 'e1')
        @ex2 = @course.exercises.create(name: 'e2')

        @user1 = FactoryBot.create(:user)
        @user2 = FactoryBot.create(:user)
        @user3 = FactoryBot.create(:user)

        sub1 = FactoryBot.create(:submission, course: @course, user: @user1, exercise: @ex1)
        sub2 = FactoryBot.create(:submission, course: @course, user: @user1, exercise: @ex2)
        sub3 = FactoryBot.create(:submission, course: @course, user: @user2, exercise: @ex2)

        FactoryBot.create(:awarded_point, course: @course, submission: sub1, user: @user1)
        FactoryBot.create(:awarded_point, course: @course, submission: sub2, user: @user1)
        FactoryBot.create(:awarded_point, course: @course, submission: sub3, user: @user2)
      end

      it 'assigns users in @students array if they have submitted exercises to the course if current user is teacher' do
        controller.current_user = @teacher
        get :index, params: { organization_id: @organization.slug, id: @course.id }
        expect(assigns(:students)).to include(@user1)
        expect(assigns(:students)).to include(@user2)
        expect(assigns(:students)).to_not include(@user3)
      end

      it 'denies access for non-teachers' do
        controller.current_user = @user
        get :index, params: { organization_id: @organization.slug, id: @course.id }
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
