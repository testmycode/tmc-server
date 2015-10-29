require 'spec_helper'

feature 'Teacher has admin abilities to own course', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization
    @student = FactoryGirl.create :user, password: 'foobar'
    @admin = FactoryGirl.create :admin, password: 'admin'

    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @course = FactoryGirl.create :course, name: 'mycourse', source_url: repo_path, organization: @organization

    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @exercise1 = @course.exercises.first
    @submission = FactoryGirl.create :submission, course: @course, user: @student, exercise: @exercise1, requests_review: true
    @submission_data = FactoryGirl.create :submission_data, submission: @submission

    visit '/'
    log_in_as(@teacher.login, 'xooxer')
  end

  def visit_course
    visit "/org/slug/courses/#{@course.name}"
  end

  scenario 'Teacher can see model solution for exercise' do
    visit "/org/slug/courses/#{@course.name}/exercises/#{@exercise1.name}"
    expect(page).to have_content('View suggested solution')

    click_link 'View suggested solution'

    expect(page).to have_content('Solution for MyExercise')
    expect(page).to have_content('src/SimpleStuff.java')
  end

  scenario 'Teacher can see all submissions for his organizations courses' do
    visit_course

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
    available_point = FactoryGirl.create :available_point, exercise: @exercise1
    available_point.award_to(@student, @submission)
    visit_course
    click_link 'View points'

    expect(page).to have_content('1/6')
    expect(page).not_to have_content('0/6')
  end

  scenario 'Teacher can make code review' do
    visit_course

    expect(page).to have_content('1 code review requested')
    click_link '1 code review requested'
    click_link 'Requested'

    fill_in('review_review_body', with: 'Code looks ok')

    page.execute_script("$('form#new_review').submit()")
    expect(page).to have_content('None at the moment.')
  end

  scenario 'Teacher can manage course feedback questions' do
    visit_course
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
    question = FactoryGirl.create :feedback_question, course: @course, question: 'Meaning of life?'
    answer = FactoryGirl.create :feedback_answer, feedback_question: question, course: @course, exercise: @exercise1, submission: @submission, answer: 'no idea'

    visit_course
    click_link 'View feedback'

    expect(page).not_to have_content('access denied')
    expect(page).to have_content('Feedback statistics')
    expect(page).to have_content(question.question)
    expect(page).to have_content(answer.answer)
  end
end
