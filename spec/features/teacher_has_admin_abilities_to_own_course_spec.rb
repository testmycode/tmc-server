# frozen_string_literal: true

require 'spec_helper'

feature 'Teacher has admin abilities to own course', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryBot.create :verified_user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization
    @student = FactoryBot.create :verified_user, password: 'foobar'
    @admin = FactoryBot.create :admin, password: 'admin'

    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @course = FactoryBot.create :course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: @organization

    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh(@teacher.id)
    RefreshCourseTask.new.run

    @exercise1 = @course.exercises.first
    @submission = FactoryBot.create :submission, course: @course, user: @student, exercise: @exercise1, requests_review: true
    @submission_data = FactoryBot.create :submission_data, submission: @submission

    visit '/'
    log_in_as(@teacher.login, 'xooxer')
  end

  scenario 'Teacher can see model solution for exercise' do
    visit '/exercises/1'
    expect(page).to have_content('View suggested solution')

    click_link 'View suggested solution'

    expect(page).to have_content('Solution for MyExercise')
    expect(page).to have_content('src/SimpleStuff.java')
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
    expect(page).not_to have_content('Forbidden')
  end

  scenario 'Teacher can see all submissions for his organization courses in course_id/submissions view' do
    visit '/org/slug/courses/1/submissions'

    expect(page).to have_content('All submissions for mycourse')
    expect(page).not_to have_content('No data available in table')
    expect(page).to have_content('Showing 1 to 1 of 1 entries')
  end

  scenario 'Teacher can see users points from his own courses' do
    available_point = FactoryBot.create :available_point, exercise: @exercise1
    available_point.award_to(@student, @submission)
    visit '/org/slug/courses/1'
    click_link 'Points list'

    expect(page).to have_content('1/6')
    expect(page).not_to have_content('0/6')
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

  scenario 'Teacher can view course feedback answers' do
    question = FactoryBot.create :feedback_question, course: @course, question: 'Meaning of life?'
    answer = FactoryBot.create :feedback_answer, feedback_question: question, course: @course, exercise: @exercise1, submission: @submission, answer: 'no idea'

    visit '/org/slug/courses/1'
    click_link 'View feedback'

    expect(page).not_to have_content('access denied')
    expect(page).to have_content('Feedback statistics')
    expect(page).to have_content(question.question)
    expect(page).to have_content(answer.answer)
  end
end
