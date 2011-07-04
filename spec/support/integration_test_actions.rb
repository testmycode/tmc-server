require File.expand_path(File.join(File.dirname(__FILE__), 'git_test_actions.rb'))

module IntegrationTestActions
  include GitTestActions

  def log_in_as(username)
    fill_in 'Login', :with => username
    fill_in 'Password', :with => 'xooxer'
    click_button 'Sign in'
    page.should have_content('Sign out')
  end
  
  def create_new_course(coursename)
    visit '/courses'
    click_link 'Create New Course'
    fill_in 'course_name', :with => coursename
    click_button 'Add Course'
    page.should have_content('Course was successfully created.')
    page.should have_content(coursename)
  end
end
