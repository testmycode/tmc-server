# frozen_string_literal: true

require 'spec_helper'

feature 'User views organization list', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @student = FactoryBot.create :verified_user, password: 'foobar'
    @student2 = FactoryBot.create :verified_user, password: 'foobar2'
    @admin = FactoryBot.create :admin, password: 'admin'

    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @course = FactoryBot.create :course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: @organization

    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @exercise1 = @course.exercises.first
    @submission = FactoryBot.create :submission, course: @course, user: @student, exercise: @exercise1, requests_review: true
    @submission_data = FactoryBot.create :submission_data, submission: @submission
    @submission2 = FactoryBot.create :submission, course: @course, user: @student2, exercise: @exercise1, requests_review: true
    @submission_data2 = FactoryBot.create :submission_data, submission: @submission2

    visit '/'
  end

  scenario 'User can see only own submissions for his courses in course_id/submissions view' do
    log_in_as(@student.email, 'foobar')
    visit '/org/slug/courses/1/submissions'

    expect(page).to have_content('All submissions for mycourse')
    expect(page).not_to have_content('No data available in table')
    expect(page).to have_content('Showing 1 to 1 of 1 entries')
    expect(page).not_to have_content(@student2.email)
  end

  scenario 'User can see only own submissions for his courses' do
    log_in_as(@student.email, 'foobar')
    visit '/org/slug/courses/1'

    expect(page).to have_content('Latest submissions')
    expect(page).not_to have_content('No data available in table')
    expect(page).to have_content('Showing 1 to 1 of 1 entries')

    click_link('Details')

    expect(page).to have_content('Submission 1')
    expect(page).to have_content('Submitted at')
    expect(page).to have_content('Test Results')
    expect(page).not_to have_content('Forbidden')
    expect(page).not_to have_content(@student2.email)
  end
end
