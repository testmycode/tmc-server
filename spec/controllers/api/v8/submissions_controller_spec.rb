require 'spec_helper'

describe Api::V8::SubmissionsController, type: :controller do
  before :each do
    @user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    @exercise = FactoryGirl.create(:exercise, course: @course)
    @submission = FactoryGirl.create(:submission,
                                     course: @course,
                                     user: @user,
                                     exercise: @exercise)
    controller.current_user = @user
  end

  describe 'as an admin' do
    before :each do
      controller.current_user = @admin
    end

    it 'should show all of the submissions' do
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      sub1 = FactoryGirl.create(:submission, user: user1, course: @course)
      sub2 = FactoryGirl.create(:submission, user: user2, course: @course)

      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).to have_content("\"user_id\"=>#{user1.id}")
      expect(json).to have_content("\"user_id\"=>#{user2.id}")
      expect(json).to have_content("\"id\"=>#{sub1.id}")
      expect(json).to have_content("\"id\"=>#{sub2.id}")
    end
  end

  describe 'as a teacher' do
    before :each do
      Teachership.create(user: @user, organization: @organization)
    end

    it 'should show all of the submissions in my organizations' do
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      sub1 = FactoryGirl.create(:submission, user: user1, course: @course)
      sub2 = FactoryGirl.create(:submission, user: user2, course: @course)

      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).to have_content("\"user_id\"=>#{user1.id}")
      expect(json).to have_content("\"user_id\"=>#{user2.id}")
      expect(json).to have_content("\"id\"=>#{sub1.id}")
      expect(json).to have_content("\"id\"=>#{sub2.id}")
    end

    it 'should not show any submissions outside my organizations' do
      other_organization = FactoryGirl.create(:accepted_organization)
      other_course = FactoryGirl.create(:course, organization: other_organization)
      other_exercise = FactoryGirl.create(:exercise, course: other_course)
      other_user = FactoryGirl.create(:user)
      other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
      expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
    end
  end

  describe 'as an assistant' do
    before :each do
      Assistantship.create(user: @user, course: @course)
    end

    it 'should show all of the submissions in my courses' do
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      sub1 = FactoryGirl.create(:submission, user: user1, course: @course)
      sub2 = FactoryGirl.create(:submission, user: user2, course: @course)

      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).to have_content("\"user_id\"=>#{user1.id}")
      expect(json).to have_content("\"user_id\"=>#{user2.id}")
      expect(json).to have_content("\"id\"=>#{sub1.id}")
      expect(json).to have_content("\"id\"=>#{sub2.id}")
    end

    it 'should not show any submissions outside my courses' do
      other_course = FactoryGirl.create(:course, organization: @organization)
      other_exercise = FactoryGirl.create(:exercise, course: other_course)
      other_user = FactoryGirl.create(:user)
      other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
      expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
    end
  end

  describe 'as a student' do
    it 'should show my own submissions' do
      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).to have_content("\"user_id\"=>#{@user.id}")
      expect(json).to have_content("\"id\"=>#{@submission.id}")
    end

    it 'should not show other users\' submissions' do
      other_user = FactoryGirl.create(:user)
      other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: @course)

      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
      expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
    end
  end

  describe ' an unauthorized user ' do
    before :each do
      controller.current_user = Guest.new
    end

    it 'should not show any submissions' do
      get :all_submissions, organization_id: @organization.slug, course_name: @course.name

      json = JSON.parse response.body

      expect(json).to have_content("[]")
    end
  end
end
