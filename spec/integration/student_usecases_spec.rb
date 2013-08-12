require 'spec_helper'

describe "The system (used by a student)", :integration => true, :js => true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @course = Course.create!(:name => 'mycourse', :source_backend => 'git', :source_url => repo_path)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @user = Factory.create(:user, :password => 'xooxer')

    visit '/'
    log_in_as(@user.login, 'xooxer')
    click_link 'mycourse'
  end

  it "should offer exercises as downloadable zips", :driver => :rack_test do
    click_link('zip')
    File.open('MyExercise.zip', 'wb') {|f| f.write(page.source) }
    system!("unzip -qq MyExercise.zip")

    File.should be_a_directory('MyExercise')
    File.should exist('MyExercise/src/SimpleStuff.java')
    File.should exist('MyExercise/test/SimpleTest.java')
    File.should_not exist('MyExercise/test/SimpleHiddenTest.java')
  end

  it "should show successful test results for correct solutions" do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    page.should have_content('All tests successful')
    page.should have_content('Ok')
    page.should_not have_content('Fail')
  end

  it "should show unsuccessful test results for incorrect solutions" do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    page.should have_content('Some tests failed')
    page.should have_content('Fail')
  end

  it "should show compilation error for uncompilable solutions" do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.introduce_compilation_error('oops')
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    page.should have_content('Compilation error')
    page.should have_content('oops')
  end

  it "should not show exercises that have been explicitly hidden" do
    @repo.set_metadata_in('MyExercise', 'hidden' => true)
    @repo.add_commit_push
    @course.refresh

    visit '/'
    click_link 'mycourse'

    page.should_not have_content('MyExercise')
  end

  it "should show exercises whose deadline has passed but without a submission form" do
    @repo.set_metadata_in('MyExercise', 'deadline' => Date.yesterday.to_s)
    @repo.add_commit_push
    @course.refresh

    visit '/'
    click_link 'mycourse'

    page.should have_content('MyExercise')
    page.should have_content('(expired)')

    click_link 'MyExercise'
    page.should have_content('(expired)')
    page.should_not have_content('Submit answer')
    page.should_not have_content('Zipped project')
  end

  it "should not accept submissions for exercises whose deadline has passed"

  it "should not accept submissions for hidden courses"

  it "should not show the submission form for unreturnable exercises"

  it "should show the files that the student submitted" do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.introduce_compilation_error('oops')
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed

    click_link 'View submitted files'
    page.should have_content('src/SimpleStuff.java')
    page.should have_content('public class')
    page.should have_content('oops')
  end

  it "should show solutions for completed exercises" do
    ex = FixtureExercise.new('SimpleExerciseWithSolutionsAndStubs', 'MyExercise')
    ex.make_zip
    
    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed
    
    visit '/'
    click_link 'mycourse'
    click_link 'MyExercise'
    click_link 'View suggested solution'
    page.should have_content('Solution for MyExercise')
    page.should have_content('src/SimpleStuff.java')
  end
  
  it "should not show solutions for uncompleted exercises" do
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_add
    ex.make_zip
    
    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    click_button 'Submit'
    wait_for_submission_to_be_processed
  
    visit '/'
    click_link 'mycourse'
    click_link 'MyExercise'
    
    page.should_not have_content('View suggested solution')
  end
end
