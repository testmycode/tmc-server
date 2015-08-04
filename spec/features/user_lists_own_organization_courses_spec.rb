require 'spec_helper'

feature 'User lists own organization courses', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @assistant = FactoryGirl.create :user, password: 'foobar'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization

    FactoryGirl.create :course, name: 'course_1', organization: @organization
    FactoryGirl.create :course, name: 'course_2', organization: @organization
    FactoryGirl.create :course, name: 'course_old', organization: @organization, hide_after: Time.now - 2.minutes
    FactoryGirl.create :course, name: 'course_disabled', organization: @organization, disabled_status: 1

    visit '/'
  end

  describe 'Teacher' do
    before :each do
      log_in_as(@teacher.login, 'xooxer')
      visit '/org/slug'
    end

    scenario 'sees both active and retired courses' do
      expect(page).to have_content('course_1')
      expect(page).to have_content('course_2')
      expect(page).to have_content('course_old')
      expect(page).to have_content('course_disabled')
    end
  end

  describe 'Assistant' do
    before :each do
      Assistantship.create! user: @assistant, course: Course.find_by(name: 'course_1')
      Assistantship.create! user: @assistant, course: Course.find_by(name: 'course_old')
      Assistantship.create! user: @assistant, course: Course.find_by(name: 'course_disabled')

      log_in_as(@assistant.login, 'foobar')
      visit '/org/slug'
    end

    scenario 'sees the courses they assist in a separate list (also disabled and expired)' do
      puts page.html
      within 'table#my-assisted-courses-table' do
        expect(page).to have_content('rourse_1')
        expect(page).to have_content('course_old')
        expect(page).to have_content('course_disabled')
        expect(page).to_not have_content('course_2')
      end
    end
  end

  describe 'Student' do
    before :each do
      FactoryGirl.create :awarded_point, user: @user, course: Course.find_by(name: 'course_1')
      FactoryGirl.create :awarded_point, user: @user, course: Course.find_by(name: 'course_old')
      FactoryGirl.create :awarded_point, user: @user, course: Course.find_by(name: 'course_disabled')

      log_in_as(@user.login, 'foobar')
      visit '/org/slug'
    end

    scenario 'sees only active courses' do
      expect(page).to have_content('course_1')
      expect(page).to have_content('course_2')
      expect(page).not_to have_content('old_course')
      expect(page).not_to have_content('disabled_course')
    end

    scenario 'sees courses they participate in a separate list (not expired or disabled)' do
      within 'table#my-courses-table' do
        expect(page).to have_content('course_1')
        expect(page).to_not have_content('course_2')
        expect(page).to_not have_content('old_course')
        expect(page).to_not have_content('disabled_course')
      end
    end
  end
end
