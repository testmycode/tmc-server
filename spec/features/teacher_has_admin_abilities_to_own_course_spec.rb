require 'spec_helper'

feature 'Teacher has admin abilities to own course', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization
    @student = FactoryGirl.create :user, password: 'foobar'
    @admin = FactoryGirl.create :admin, password: 'admin'

    @course = FactoryGirl.create :course, name: 'mycourse', source_url: 'https://github.com/testmycode/tmc-testcourse.git', organization: @organization
    @course.refresh

    @exercise1 = @course.exercises.find_by(name: 'arith_funcs')
    @submission = FactoryGirl.create :submission, course: @course, user: @student, exercise: @exercise1, requests_review: true
    @submission_data = FactoryGirl.create :submission_data, submission: @submission

    visit '/'
    log_in_as(@teacher.login, 'xooxer')
  end

  scenario 'Teacher can see model solution for exercise' do
    visit '/exercises/1'
    expect(page).to have_content('View suggested solution')

    click_link 'View suggested solution'

    expect(page).to have_content('Solution for arith_funcs')
    expect(page).to have_content('src/Arith.java')
  end

  scenario 'Teacher can see all submissions for his organizations courses' do
    visit '/org/slug/courses/1'

    expect(page).to have_content('Latest submissions')
    expect(page).not_to have_content('No data available in table')
    expect(page).to have_content('Showing 1 to 1 of 1 entries')

    click_link('Details')

    expect(page).to have_content('Submission 1')
    expect(page).to have_content('Submitted at')
    expect(page).to have_content('Test Results')
    expect(page).not_to have_content('Access denied')
  end

  scenario 'Teacher can see users points from his own courses' do
    available_point = @course.available_points.find_by(name: 'arith-funcs')
    available_point.award_to(@student, @submission)
    visit '/org/slug/courses/1'
    click_link 'View points'

    expect(page).to have_content('1/8')
    expect(page).not_to have_content('0/8')
  end

  scenario 'Teacher can make code review' do
    visit '/org/slug/courses/1'

    expect(page).to have_content('1 code review requested')
    click_link '1 code review requested'
    click_link 'Requested'

    fill_in('review_review_body', with: 'Code looks ok')

    page.execute_script("$('form#new_review').submit()")
    expect(page).to have_content('None at the moment.')
  end

  scenario 'Teacher can manage course feedback questions' do
    visit '/org/slug/courses/1'
    click_link 'Manage feedback questions'
    click_link 'Add question'

    fill_in('feedback_question_question', with: 'Meaning of life?')
    fill_in('feedback_question_title', with: 'meaning')
    choose('feedback_question_kind_text')
    click_button('Create question')

    expect(page).to have_content('Feedback questions for mycourse')
    expect(page).to have_content('Meaning of life?')

    click_link('Meaning of life?')
    fill_in('feedback_question_question', with: 'Your feelings?')
    click_button('Save')

    expect(page).to have_content('Feedback questions for mycourse')
    expect(page).to have_content('Your feelings?')

    click_link('Delete')
    expect(page).to have_content('No feedback questions set.')
  end
end
