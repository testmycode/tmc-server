require 'spec_helper'

describe "The system" do
  include IntegrationTestActions
  include SystemCommands

  it "should show the university name on the front page" do
    visit '/'
    page.should have_content('HELSINKI UNIVERSITY')
  end

  describe "(used by an instructor)" do
  
    before :each do
      visit '/'
      @user = User.create!(:login => 'user', :password => 'xooxer')
      log_in_as(@user.login)
    end
    
    it "should create a git repository for new courses" do
      create_new_course('mycourse')
      bare_repo_path = GitBackend.repositories_root + '/mycourse.git'
      File.should exist(bare_repo_path)
    end
    
    it "should show exercises pushed to the course's git repo" do
      create_new_course('mycourse')
      course = Course.find_by_name!('mycourse')
      
      repo = clone_course_repo(course)
      repo.copy_model_exercise('MyExercise')
      repo.add_commit_push
      
      visit "/courses/#{course.id}/refresh" #FIXME FIXME FIXME - shouldn't be needed
      
      visit '/courses'
      click_link 'mycourse'
      page.should have_content('MyExercise')
    end
    
  end
end
