require 'spec_helper'

describe "The system (used by an instructor for viewing statistics)", type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    course = Course.create!(name: 'mycourse', source_backend: 'git', source_url: repo_path)
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('EasyExercise')
    repo.copy_simple_exercise('HardExercise')
    repo.add_commit_push

    course.refresh
  end

  it "should show recent submissions for an exercise" do
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
    user = FactoryGirl.create(:admin, password: 'xooxer')
    log_in_as(user.login, 'xooxer')
  end

  def visit_exercise(exercise_name)
    visit '/'
    click_link 'mycourse'
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

    visit '/'
    click_link 'mycourse'
    first('.exercise-list').click_link exercise_name
    attach_file('Zipped project', "#{exercise_name}.zip")
    click_button 'Submit'
    wait_for_submission_to_be_processed
  end

end
