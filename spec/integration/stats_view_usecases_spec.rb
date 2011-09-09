require 'spec_helper'

describe "The system (used by an instructor for viewing statistics)" do
  include IntegrationTestActions

  before :each do
    course = Course.create!(:name => 'mycourse')
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('EasyExercise')
    repo.copy_simple_exercise('HardExercise')
    repo.add_commit_push

    course.refresh
  end

  it "should show all submissions for an exercise" do
    submit_exercise('EasyExercise', :solve => true, :username => '123')
    submit_exercise('EasyExercise', :solve => false, :username => '456')
    submit_exercise('EasyExercise', :compilation_error => true, :username => '789')

    log_in_as_instructor
    click_link 'mycourse'
    click_link 'EasyExercise'

    page.should have_content('123')
    page.should have_content('456')
    page.should have_content('789')
    page.should have_content('Ok')
    page.should have_content('Fail')
    page.should have_content('Error')
  end

  def submit_exercise(exercise_name, options = {})
    options = {
      :solve => true,
      :compilation_error => false,
      :username => 'some_username'
    }.merge(options)

    FileUtils.rm_rf exercise_name
    ex = SimpleExercise.new(exercise_name)
    ex.solve_all if options[:solve]
    ex.introduce_compilation_error('oops') if options[:compilation_error]
    ex.make_zip

    visit '/'
    click_link 'mycourse'
    click_link exercise_name
    fill_in 'Student number', :with => options[:username]
    attach_file('Zipped project', "#{exercise_name}.zip")
    click_button 'Submit'
  end

  def log_in_as_instructor
    visit '/'
    user = User.create!(:login => 'user', :password => 'xooxer', :administrator => true)
    log_in_as(user.login)
  end

end
