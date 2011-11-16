require File.expand_path(File.join(File.dirname(__FILE__), 'git_test_actions.rb'))

module IntegrationTestActions
  include GitTestActions
  include SystemCommands

  def log_in_as(username, password)
    fill_in 'Login', :with => username
    fill_in 'Password', :with => password
    click_button 'Sign in'
    
    page.should have_content('Sign out')
  end
  
  def create_new_course(options = {})
    visit '/courses'
    click_link 'Create New Course'
    fill_in 'course_name', :with => options[:name]
    fill_in 'course_source_backend', :with => options[:source_backend] if options[:source_backend]
    fill_in 'course_source_url', :with => options[:source_url] if options[:source_url]
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
  
  # Evil override fix for Capybara 1.1.2 + Selenium + Firefox 7.
  # From http://how.itnig.net/facts/attach-file-in-capybara---selenium-webdriver
  def attach_file(field_locator, file_name)
    case Capybara.current_driver
    when :selenium
      find_field(field_locator).native.send_keys(File.expand_path(file_name))
    else
      super
    end
  end
  
  def wait_for_submission_to_be_processed
    wait_for_with_timeout(true, 60) do
      if page.has_content?('Processing...')
        sleep 1
        false
      else
        true
      end
    end
  end
  
  def wait_for_with_timeout(expected, timeout, &block)
    start_time = Time.now
    while block.call != expected
      if Time.now - start_time > timeout
        raise 'timeout'
      end
    end
  end
end
