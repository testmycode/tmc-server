require 'spec_helper'

feature 'User lists own organization courses', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @assistant = FactoryGirl.create :user, password: 'foobar'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization

    FactoryGirl.create :course, name: 'course_1', title: 'Course 1', organization: @organization
    FactoryGirl.create :course, name: 'course_2', title: 'Course 2', organization: @organization
    FactoryGirl.create :course, name: 'course_3', title: 'Course 3', organization: @organization, hide_after: Time.now - 2.minutes
    FactoryGirl.create :course, name: 'course_4', title: 'Course 4', organization: @organization, disabled_status: 1

    visit '/'
  end

  describe 'Teacher' do
    before :each do
      log_in_as(@teacher.login, 'xooxer')
      visit '/org/slug'
    end

    scenario 'sees both active and retired courses' do
      expect(page).to have_content('Course 1')
      expect(page).to have_content('Course 2')
      expect(page).to have_content('Course 3')
      expect(page).to have_content('Course 4')
    end
  end

  describe 'Assistant' do
    before :each do
      Assistantship.create! user: @assistant, course: Course.find_by(name: 'course_1')
      Assistantship.create! user: @assistant, course: Course.find_by(name: 'course_2')
      Assistantship.create! user: @assistant, course: Course.find_by(name: 'course_4')

      log_in_as(@assistant.login, 'foobar')
      visit '/org/slug'
    end

    scenario 'sees the courses they assist in a separate list (also disabled and expired)' do
      within 'table#my-assisted-courses-table' do
        expect(page).to have_content('course_1')
        expect(page).to have_content('course_2')
        expect(page).to have_content('course_4')
        expect(page).to_not have_content('course_3')
      end
    end
  end

  describe 'Student' do
    before :each do
      FactoryGirl.create :awarded_point, user: @user, course: Course.find_by(name: 'course_1')
      FactoryGirl.create :awarded_point, user: @user, course: Course.find_by(name: 'course_2')
      FactoryGirl.create :awarded_point, user: @user, course: Course.find_by(name: 'course_4')

      log_in_as(@user.login, 'foobar')
      visit '/org/slug'
    end

    scenario 'sees only active courses' do
      expect(page).to have_content('course_1')
      expect(page).to have_content('course_2')
      expect(page).not_to have_content('course_3')
      expect(page).not_to have_content('course_4')
    end

    scenario 'sees courses they participate in a separate list (not expired or disabled)' do
      within 'table#my-courses-table' do
        expect(page).to have_content('course_1')
        expect(page).to have_content('course_2')
        expect(page).to_not have_content('course_3')
        expect(page).to_not have_content('course_4')
      end
    end
  end
end
