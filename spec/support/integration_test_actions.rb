module IntegrationTestActions
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
  
  def clone_course_repo(coursename)
    FileUtils.pwd.start_with?(@test_tmp_dir).should == true
    course = Course.find_by_name(coursename)
    system! "git clone -q #{course.bare_path} #{coursename}"
  end
end
