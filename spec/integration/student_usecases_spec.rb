# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe 'The system (used by a student)', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryGirl.create(:verified_user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id
    @course = FactoryGirl.create(:course, name: 'mycourse', title: 'mycourse', source_url: repo_path, organization: @organization)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @user = FactoryGirl.create(:verified_user, password: 'xooxer')
    @ability = Ability.new(@user)
    visit '/'

    log_in_as(@user.email, 'xooxer')
    visit '/org/slug/courses'
    click_link 'mycourse'
  end

  # :rack_test seems to handle downloads better than :webkit/:selenium atm
  it 'should offer exercises as downloadable zips', driver: :rack_test do
    click_link('zip')
    File.open('MyExercise.zip', 'wb') { |f| f.write(page.source) }
    system!('unzip -qq MyExercise.zip')

    expect(File).to be_a_directory('MyExercise')
    expect(File).to exist('MyExercise/src/SimpleStuff.java')
    expect(File).to exist('MyExercise/test/SimpleTest.java')
    expect(File).not_to exist('MyExercise/test/SimpleHiddenTest.java')
  end

  it 'should show successful test results for correct solutions' do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    expect(page).to have_content('All tests successful')
    expect(page).to have_content('Ok')
    expect(page).not_to have_content('Fail')
  end

  it 'should show unsuccessful test results for incorrect solutions' do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    expect(page).to have_content('Some tests failed')
    expect(page).to have_content('Fail')
  end

  it 'should show compilation error for uncompilable solutions' do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.introduce_compilation_error('oops')
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    expect(page).to have_content('Compilation error')
    expect(page).to have_content('oops')
  end

  it 'should not show exercises that have been explicitly hidden' do
    @repo.set_metadata_in('MyExercise', 'hidden' => true)
    @repo.add_commit_push
    @course.refresh

    visit '/org/slug/courses'
    click_link 'mycourse'

    expect(page).not_to have_content('MyExercise')
  end

  it 'should show exercises whose deadline has passed but without a submission form' do
    @course.exercise_group_by_name('').hard_group_deadline = [Date.yesterday.to_s].to_json

    visit '/org/slug/courses'
    click_link 'mycourse'

    expect(page).to have_content('MyExercise')
    expect(page).to have_content('(expired)')

    click_link 'MyExercise'
    expect(page).to have_content('(expired)')
    expect(page).not_to have_content('Submit answer')
    expect(page).not_to have_content('Zipped project')
  end

  it 'should not accept submissions for exercises whose deadline has passed'

  it 'should not accept submissions for hidden courses'

  it 'should not show the submission form for unreturnable exercises'

  it 'should show the files that the student submitted including extra student files' do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.introduce_compilation_error('oops')
    @repo = clone_course_repo(@course)
    exx = @repo.copy_simple_exercise('MyExercise')
    exx.write_file('.tmcproject.yml', "extra_student_files:\n  - test/extraFile.java\n")
    @repo.add_commit_push

    @course.refresh

    ex.write_file('test/extraFile.java', 'extra_file')
    ex.make_zip(src_only: false)

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    click_link 'Files'

    expect(page).to have_content('src/SimpleStuff.java')
    expect(page).to have_content('public class')
    expect(page).to have_content('oops')

    expect(page).to have_content('test/extraFile.java')
    expect(page).to have_content('extra_file')

    expect(page).not_to have_content('test/SimpleTest.java')
  end

  it 'should show solutions for completed exercises' do
    ex = FixtureExercise.new('SimpleExerciseWithSolutionsAndStubs', 'MyExercise')
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    visit '/org/slug/courses'
    within '#ongoing-courses' do click_link 'mycourse' end
    first('.exercise-list').click_link 'MyExercise'
    click_link 'View suggested solution'
    expect(page).to have_content('Solution for MyExercise')
    expect(page).to have_content('src/SimpleStuff.java')
  end

  it 'should not show solutions for uncompleted exercises' do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_add
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    visit '/org/slug/courses'
    click_link 'mycourse'
    first('.exercise-list').click_link 'MyExercise'

    expect(page).not_to have_content('View suggested solution')
  end

  it 'should not count submissions made by non legitimate_students in submission counts' do
    @fake_user = FactoryGirl.create(:admin, login: 'uuseri', password: 'xooxer', legitimate_student: false)
    log_out
    visit '/org/slug/courses'
    log_in_as(@fake_user.login, 'xooxer')

    FixtureExercise::SimpleExercise.new('MyExercise')
    Submission.create!(exercise_name: 'MyExercise', course_id: 1, processed: true, secret_token: nil, all_tests_passed: true, points: 'addsub both-test-files justsub mul simpletest-all', user: @fake_user)

    click_link 'mycourse'
    expect(page).to have_content('Number of submissions (from actual users): 0')
  end

  it 'should not show submission files to other users' do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    # check('paste')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    expect(@ability).to be_able_to(:read, Submission.last)
    expect(page).to have_content('All tests successful')
    expect(page).to have_content('Ok')

    click_link 'Files'
    expect(page).to have_content('src/SimpleStuff.java')

    log_out
    expect(page).not_to have_content('src/SimpleStuff.java')
    expect(page).to have_content('Goodbye')
    @other_user = FactoryGirl.create(:user, login: 'uuseri', password: 'xooxer')

    visit '/org/slug/courses'
    log_in_as(@other_user.login, 'xooxer')

    @ability = Ability.new(@other_user)

    expect(@ability).not_to be_able_to(:read, Submission.last)

    visit submission_path(Submission.last, anchor: 'files')

    expect(page).not_to have_content('src/SimpleStuff.java')
    expect(page).to have_content('Access denied')
  end

  it 'should show checkstyle validation results' do
    @repo.copy_fixture_exercise('SimpleExerciseWithValidationErrors', 'MyValidationExercise')
    @repo.add_commit_push
    @course.refresh
    @course.exercises.find_by(name: 'MyValidationExercise').enabled!
    visit current_path

    ex = FixtureExercise.new('SimpleExerciseWithValidationErrors', 'MyValidationExercise')
    ex.make_zip

    click_link 'MyValidationExercise'
    attach_file('Zipped project', 'MyValidationExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    expect(page).to have_content('Some tests failed')

    expect(page).to have_content('src/SimpleStuff.java')

    expect(page).to have_content('Validation Cases')
    expect(page).to have_content('is not preceded with whitespace')
    expect(page).to have_content('Indentation incorrect. Expected 8, but was 4')
  end
end
