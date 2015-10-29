require 'spec_helper'

describe 'Teacher can hide submission results from users', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization
    @course = FactoryGirl.create :course, organization: @organization
    @course.hide_submission_results = true
    @course.save!
    @exercise = FactoryGirl.create(:exercise, course: @course)
    @available_point = FactoryGirl.create(:available_point, exercise: @exercise)
    @submission = FactoryGirl.create(:submission,
                                     course: @course,
                                     user: @user,
                                     exercise: @exercise)
    @awarded_point = FactoryGirl.create(:awarded_point,
                                        course: @course,
                                        name: @available_point.name,
                                        submission: @submission,
                                        user: @user)
    @submission.awarded_points << @awarded_point
    @submission.save!
    visit '/'
  end

  def visit_course
    visit "/org/#{@organization.slug}/courses/#{@course.name}"
  end

  scenario "Teacher can see button 'Unhide submisson results' when result are hidden" do
    log_in_as(@teacher.username, 'xooxer')
    visit_course
    expect(page).to have_content('Unhide submission results')
  end

  scenario 'In course page user can not see results of submission and link to points page' do
    pending('Waiting for clients to be updated')
    log_in_as(@user.username, 'foobar')
    visit_course
    expect(page).to_not have_link('View points')
    expect(page.find_by_id('submissions').find('tr', text: @user.username)).to have_content('Hidden')
  end

  scenario 'In My stats page user can not see results of submission' do
    pending('Waiting for clients to be updated')
    log_in_as(@user.username, 'foobar')
    visit_course
    click_link('My stats')
    expect(page).to have_content('For this course points are not visible')
    expect(page.find_by_id('submissions').find('tr', text: @user.username)).to have_content('Hidden')
  end

  scenario 'In submission page user can not see results of submission' do
    FactoryGirl.create :submission_data, submission: @submission
    tcr = FactoryGirl.create :test_case_run, submission: @submission
    log_in_as(@user.username, 'foobar')
    visit_course
    click_link('Details')
    expect(page).to have_content('All tests done - results are hidden')
    expect(page).to_not have_content('Got 1 out of 1 point')
    expect(page).to_not have_link('View suggested solution')
    click_link('Test Results')
    expect(page).to have_content('Test Cases')
    expect(find('tr', text: tcr.test_case_name)).to have_content('Hidden')
    expect(find('tr', text: tcr.test_case_name).all('td').count).to eq(2)
  end

  scenario 'when c language exercise then in submission page user can not see results of submission' do
    FactoryGirl.create :submission_data, submission: @submission
    tcr = FactoryGirl.create :test_case_run, submission: @submission
    @submission.stdout = 'some stdout text'
    @submission.stderr = 'some stderr text'
    @submission.valgrind = 'some valgrind text'
    @submission.save!
    log_in_as(@user.username, 'foobar')
    visit_course
    click_link('Details')
    expect(page).to have_content('All tests done - results are hidden')
    expect(page).to_not have_content('Got 1 out of 1 point')
    expect(page).to_not have_link('View suggested solution')
    click_link('Test Results')
    expect(page).to have_content('Test Cases')
    expect(find('tr', text: tcr.test_case_name)).to have_content('Hidden')
    expect(find('tr', text: tcr.test_case_name).all('td').count).to eq(2)
    expect(find_by_id('myTab').all('li').count).to eq(2)
  end
end