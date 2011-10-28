require File.expand_path(File.join(File.dirname(__FILE__), 'git_test_actions.rb'))

module IntegrationTestActions
  include GitTestActions
  include SystemCommands

  def log_in_as(username)
    fill_in 'Login', :with => username
    fill_in 'Password', :with => 'xooxer'
    click_button 'Sign in'
    page.should have_content('Sign out')
  end
  
  def create_new_course(options = {})
    visit '/courses'
    click_link 'Create New Course'
    fill_in 'course_name', :with => options[:name]
    fill_in 'course_remote_repo_url', :with => options[:remote_repo_url] if options[:remote_repo_url]
    click_button 'Add Course'
    
    page.should have_content('Course was successfully created.')
    page.should have_content(options[:name])
  end
  
  def manually_refresh_course(coursename)
    visit '/courses'
    click_link coursename
    click_button 'Refresh from repository'
    page.should have_content('Course refreshed from repository.')
  end
end
