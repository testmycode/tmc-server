# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher can edit course parameters', feature: true do
  include IntegrationTestActions

  before :each do
    @user = FactoryGirl.create :user, password: 'xooxer'
    @teacher = FactoryGirl.create :user, password: 'foobar'
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @course = FactoryGirl.create :course, name: 'oldTitle', title: 'oldTitle', description: 'oldDescription', material_url: 'oldMaterial.com', organization: @organization
    FactoryGirl.create :course, title: 'dontchange', organization: @organization
    Teachership.create!(user: @teacher, organization: @organization)
    visit '/org/slug'
  end

  scenario 'Teacher succeeds at editing title, description and material url' do
    log_in_as @teacher.email, 'foobar'
    visit '/org/slug'
    link = find(:link, 'oldTitle')
    link.trigger('click')
    #click_link 'oldTitle'
    click_link 'Edit course details'

    fill_in 'course_title', with: 'newTitle'
    fill_in 'course_description', with: 'newDescription'
    fill_in 'course_material_url', with: 'newMaterial.com'
    click_button 'Update course information'

    expect(page).to have_content 'newTitle'
    expect(page).to have_content 'newDescription'
    expect(page).to have_link 'Course material', href: 'http://newMaterial.com'

    visit '/org/slug'
    expect(page).to have_content 'newTitle'
    expect(page).to have_content 'dontchange'
  end

  scenario 'Teacher cannot edit if parameters are invalid' do
    log_in_as @teacher.email, 'foobar'
    visit '/org/slug'
    # click_link 'oldTitle'
    link = find(:link, 'oldTitle')
    link.trigger('click')
    click_link 'Edit course details'

    fill_in 'course_title', with: 'a' * 81
    click_button 'Update course information'

    expect(page).to have_content 'Title is too long'

    visit '/org/slug'
    expect(page).to have_content 'oldTitle'
    expect(page).to have_content 'dontchange'

    # click_link 'oldTitle'
    link = find(:link, 'oldTitle')
    link.trigger('click')
    expect(page).to have_content 'oldTitle'
    expect(page).to have_content 'oldDescription'
    expect(page).to have_link 'Course material', href: 'http://oldMaterial.com'
  end

  scenario 'Teacher cannot edit courses that they dont teach' do
    log_in_as @user.email, 'xooxer'
    visit '/org/slug'
    link = find(:link, 'oldTitle')
    link.trigger('click')
    expect(page).not_to have_button 'Update Course'
  end

  describe 'Teacher sets custom points URL with dynamic parameters' do
    before :each do
      log_in_as @teacher.email, 'foobar'
      visit '/org/slug'
      # click_link 'oldTitle'
      link = find(:link, 'oldTitle')
      link.trigger('click')
      click_link 'Edit course details'

      fill_in 'course_external_scoreboard_url', with: 'http://example.com/%{org}/%{course}/%{user}'
      click_button 'Update course information'
      log_out
    end

    scenario 'Teacher can see the URL correctly' do
      log_in_as @teacher.email, 'foobar'
      visit '/org/slug'
      # click_link 'oldTitle'
      link = find(:link, 'oldTitle')
      link.trigger('click')

      expect(page).to have_link('Points list', href: "http://example.com/slug/#{@course.id}/#{@teacher.login}")
    end

    scenario 'Guest cannot see the custom URL' do
      visit '/org/slug'
      # click_link 'oldTitle'
      link = find(:link, 'oldTitle')
      link.trigger('click')

      expect(page).to_not have_link('Points list')
    end

    scenario 'Student cannot see the custom URL if they have no submissions in the course' do
      log_in_as @user.email, 'xooxer'
      visit '/org/slug'
      # click_link 'oldTitle'
      link = find(:link, 'oldTitle')
      link.trigger('click')

      expect(page).to_not have_link('Points list')
    end

    scenario 'Student can see the custom URL correctly if they have submissions in the course' do
      exercise = FactoryGirl.create(:exercise, course: @course)
      submission = FactoryGirl.create(:submission, course: @course, user: @user, exercise: exercise)
      FactoryGirl.create(:awarded_point, course: @course, user: @user, submission: submission)

      log_in_as @user.email, 'xooxer'
      visit '/org/slug'
      link = find(:link, 'oldTitle')
      link.trigger('click')

      expect(page).to have_link('Points list', href: "http://example.com/slug/#{@course.id}/#{@user.login}")
    end
  end
end
