require 'fileutils'
require File.expand_path(File.join(File.dirname(__FILE__), 'git_test_actions.rb'))

module IntegrationTestActions
  include GitTestActions
  include SystemCommands

  def log_in_as(username, password)
    fill_in 'session_login', with: username
    fill_in 'session_password', with: password
    click_button 'Sign in'

    expect(page).to have_content('Sign out')
  end

  def log_out
    click_link 'Sign out'
  end

  def create_new_course(options = {})
    visit "/org/#{options[:organization_slug]}/courses"
    #save_and_open_page
    click_link 'Create New Course'
    fill_in 'course_name', with: options[:name]
    # fill_in 'course_source_backend', :with => options[:source_backend] if options[:source_backend]
    fill_in 'course_source_url', with: options[:source_url] if options[:source_url]
    click_button 'Add Course'

    expect(page).to have_content('Course was successfully created.')
    expect(page).to have_content(options[:name])
  end

  def manually_refresh_course(coursename, organization_slug)
    visit "/org/#{organization_slug}/courses"
    click_link coursename
    click_on 'Refresh'
    expect(page).to have_content('Refresh successful.')
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
      if page.has_content?('Processing')
        sleep 1
        false
      else
        true
      end
    end
  end

  # :deprecated:
  def wait_for_with_timeout(expected, timeout, &block)
    wait_until(timeout: timeout) {
      block.call == expected
    }
  end

  def wait_until(options = {}, &block)
    options = {
      timeout: 15,
      sleep_time: 0.1
    }.merge(options)
    start_time = Time.now
    until block.call
      if Time.now - start_time > options[:timeout]
        fail 'timeout'
      end
      sleep options[:sleep_time]
    end
  end

  def screenshot_to_file(path)
    FileUtils.mkdir_p(File.dirname(path))
    if page.driver.respond_to? :render
      page.driver.render(path) # Webkit
    else
      page.driver.browser.save_screenshot(path) # Selenium
    end
    trim_image_edges(path)
  end

  private

  def trim_image_edges(path)
    cmd = mk_command [
      'convert',
      '-trim',
      path,
      path + '.tmp'
    ]
    cmd2 = mk_command [
      'mv',
      '-f',
      path + '.tmp',
      path
    ]

    # todo: put these in the background and ensure they finish before in an after :suite block
    system!(cmd)
    system!(cmd2)
  end
end
