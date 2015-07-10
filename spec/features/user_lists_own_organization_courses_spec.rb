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
    FactoryGirl.create :course, name: 'course_old', title: 'Old Course', organization: @organization, hide_after: Time.now - 2.minutes
    FactoryGirl.create :course, name: 'course_disabled', title: 'Disabled Course', organization: @organization, disabled_status: 1

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
      expect(page).to have_content('Old Course')
      expect(page).to have_content('Disabled Course')
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
      within 'table#my-assisted-courses-table' do
        expect(page).to have_content('Course 1')
        expect(page).to have_content('Old Course')
        expect(page).to have_content('Disabled Course')
        expect(page).to_not have_content('Course 2')
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
      expect(page).to have_content('Course 1')
      expect(page).to have_content('Course 2')
      expect(page).not_to have_content('Old Course')
      expect(page).not_to have_content('Disabled Course')
    end

    scenario 'sees courses they participate in a separate list (not expired or disabled)' do
      within 'table#my-courses-table' do
        expect(page).to have_content('Course 1')
        expect(page).to_not have_content('Course 2')
        expect(page).to_not have_content('Old Course')
        expect(page).to_not have_content('Disabled Course')
      end
    end
  end
end
