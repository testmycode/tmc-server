require 'spec_helper'

describe "The system (used by an instructor for administration)", :integration => true do
  include IntegrationTestActions

  before :each do
    visit '/'
    @user = User.create!(:login => 'user', :password => 'xooxer', :administrator => true)
    log_in_as(@user.login, 'xooxer')
    
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(@repo_path)
  end
  
  it "should allow using a git repo as a source for a new course" do
    create_new_course(:name => 'mycourse', :source_backend => 'git', :source_url => @repo_path)
  end
  
  it "should show all exercises pushed to the course's git repo" do
    create_new_course(:name => 'mycourse', :source_backend => 'git', :source_url => @repo_path)
    course = Course.find_by_name!('mycourse')
    
    repo = clone_course_repo(course)
    repo.copy_simple_exercise('MyExercise', :deadline => (Date.today - 1.day).to_s)
    repo.add_commit_push
    
    manually_refresh_course('mycourse')
    
    visit '/courses'
    click_link 'mycourse'
    page.should have_content('MyExercise')
  end
  
  it "should allow rerunning individual submissions" do
    setup = SubmissionTestSetup.new(:solve => true, :save => true)
    setup.make_zip
    setup.submission.processed = true
    setup.submission.pretest_error = "some funny error"
    setup.submission.test_case_runs.each do |tcr|
      tcr.successful = false
      tcr.save!
    end
    setup.submission.save!
    
    visit submission_path(setup.submission)
    page.should_not have_content('All tests successful')
    
    click_button 'Rerun submission'
    page.should have_content('Rerun scheduled')
    wait_for_submission_to_be_processed
    
    page.should_not have_content('some funny error')
    page.should have_content('All tests successful')
  end
end

