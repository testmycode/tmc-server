# frozen_string_literal: true

require 'spec_helper'

describe 'The system (used by an instructor for viewing statistics)', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    teacher = FactoryBot.create(:user)
    Teachership.create user_id: teacher.id, organization_id: organization.id
    course = FactoryBot.create(:course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: organization)
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('EasyExercise')
    repo.copy_simple_exercise('HardExercise')
    repo.add_commit_push

    course.refresh(teacher.id)
    RefreshCourseTask.new.run
  end

  it 'should show recent submissions for an exercise' do
    skip 'Not working, requires sandbox setup for testing'
    log_in_as_instructor

    submit_exercise('EasyExercise', solve: true)
    submit_exercise('EasyExercise', solve: false)
    submit_exercise('EasyExercise', compilation_error: true)

    visit_exercise 'EasyExercise'

    expect(page).to have_content('Ok')
    expect(page).to have_content('Fail')
    expect(page).to have_content('Error')
  end

  def log_in_as_instructor
    visit '/'
    user = FactoryBot.create(:admin, password: 'xooxer')
    log_in_as(user.login, 'xooxer')
  end

  def visit_exercise(exercise_name)
    visit '/org/slug/courses'
    within '#ongoing-courses' do click_link 'mycourse' end
    first('.exercise-list').click_link exercise_name
  end

  def submit_exercise(exercise_name, options = {})
    options = {
      solve: true,
      compilation_error: false
    }.merge(options)

    FileUtils.rm_rf exercise_name
    ex = FixtureExercise::SimpleExercise.new(exercise_name)
    ex.solve_all if options[:solve]
    ex.introduce_compilation_error('oops') if options[:compilation_error]
    ex.make_zip

    visit '/org/slug/courses'
    within '#ongoing-courses' do click_link 'mycourse' end
    first('.exercise-list').click_link exercise_name
    attach_file('Zipped project', "#{exercise_name}.zip")
    click_button 'Submit'
    wait_for_submission_to_be_processed
  end
end
