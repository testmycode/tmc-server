# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher can hide submission results from users', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryBot.create :accepted_organization
    @teacher = FactoryBot.create :verified_user, password: 'xooxer'
    @user = FactoryBot.create :verified_user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization
    @course = FactoryBot.create :course, organization: @organization
    @course.hide_submission_results = true
    @course.save!
    @exercise = FactoryBot.create(:exercise, course: @course)
    @available_point = FactoryBot.create(:available_point, exercise: @exercise)
    @submission = FactoryBot.create(:submission,
                                     course: @course,
                                     user: @user,
                                     exercise: @exercise)
    @awarded_point = FactoryBot.create(:awarded_point,
                                        course: @course,
                                        name: @available_point.name,
                                        submission: @submission,
                                        user: @user)
    @submission.awarded_points << @awarded_point
    @submission.save!
    visit '/'
  end

  def visit_course
    visit "/org/#{@organization.slug}/courses/#{@course.id}"
  end

  scenario "Teacher can see button 'Disable exam mode' when result are hidden" do
    log_in_as(@teacher.login, 'xooxer')
    visit_course
    expect(page).to have_content('Disable exam mode')
  end

  scenario 'In course page user can not see results of submission and link to points page' do
    log_in_as(@user.login, 'foobar')
    visit_course
    expect(page).to_not have_link('Points list')
    expect(page.find_by_id('submissions').find('tr', text: @user.username)).to have_content('Hidden')
  end

  scenario 'In My stats page user can not see results of submission' do
    log_in_as(@user.login, 'foobar')
    visit_course
    link = first(:link, @user.email)
    link.trigger('click')
    expect(page).to have_content('For this course points are not visible')
    expect(page.find_by_id('submissions').find('tr', text: @user.username)).to have_content('Hidden')
  end

  scenario 'In submission page user can not see results of submission' do
    FactoryBot.create :submission_data, submission: @submission
    tcr = FactoryBot.create :test_case_run, submission: @submission
    log_in_as(@user.login, 'foobar')
    visit_course
    click_link('Details')
    expect(page).to have_content('All tests done - results are hidden')
    expect(page).to_not have_content('Got 1 out of 1 point')
    expect(page).to_not have_link('View suggested solution')
    click_link('Test Results')
    expect(page).to have_content('Test Cases')
    # expect(find('tr', text: tcr.test_case_name)).to have_content('Hidden')
    expect(find('tr').all('td').count).to eq(0)
  end

  scenario 'In submission page user can not see model solution when all tests passed' do
    FactoryBot.create :submission_data, submission: @submission
    tcr = FactoryBot.create :test_case_run, submission: @submission
    @submission.stdout = 'some stdout text'
    @submission.stderr = 'some stderr text'
    @submission.valgrind = 'some valgrind text'
    @submission.all_tests_passed = true
    @submission.save!
    log_in_as(@user.login, 'foobar')
    visit_course
    click_link('Details')
    expect(page).to have_content('All tests done - results are hidden')
    expect(page).to_not have_content('Got 1 out of 1 point')
    expect(page).to_not have_link('View suggested solution')
  end

  scenario 'when c language exercise then in submission page user can not see results of submission' do
    FactoryBot.create :submission_data, submission: @submission
    tcr = FactoryBot.create :test_case_run, submission: @submission
    @submission.stdout = 'some stdout text'
    @submission.stderr = 'some stderr text'
    @submission.valgrind = 'some valgrind text'
    @submission.all_tests_passed = true
    @submission.save!
    log_in_as(@user.login, 'foobar')
    visit_course
    click_link('Details')
    expect(page).to have_content('All tests done - results are hidden')
    expect(page).to_not have_content('Got 1 out of 1 point')
    expect(page).to_not have_link('View suggested solution')
    click_link('Test Results')
    expect(page).to have_content('Test Cases')
    # expect(find('tr', text: tcr.test_case_name)).to have_content('Hidden')
    expect(find('tr').all('td').count).to eq(0)
    # expect(find_by_id('myTab').all('li').count).to eq(2)
  end

  context 'when submission results are hidden for an individual exercise' do
    scenario 'In submission page user can not see results of submission' do
      @course.hide_submission_results = false
      @course.save!
      @exercise.hide_submission_results = true
      @exercise.save!
      @submission.all_tests_passed = true
      @submission.save!
      FactoryBot.create :submission_data, submission: @submission
      tcr = FactoryBot.create :test_case_run, submission: @submission
      log_in_as(@user.login, 'foobar')
      visit_course
      click_link('Details')
      expect(page).to have_content('All tests done - results are hidden')
      expect(page).to_not have_content('Got 1 out of 1 point')
      expect(page).to_not have_link('View suggested solution')
      click_link('Test Results')
      expect(page).to have_content('Test Cases')
      expect(find('tr').all('td').count).to eq(0)
      # expect(find('tr', text: tcr.test_case_name)).to have_content('Hidden')
      # expect(find('tr', text: tcr.test_case_name).all('td').count).to eq(2)
    end
  end
end
