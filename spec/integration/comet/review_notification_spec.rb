require 'spec_helper'

describe "Notifications about new code reviews via HTTP push", :type => :request, :integration => true do
  include IntegrationTestActions

  before :each do
    CometSupport.ensure_started!

    @admin = Factory.create(:admin)
    @user = Factory.create(:user)
    @course = Factory.create(:course)
    @exercise = Factory.create(:exercise, :course => @course)
    @submission = Factory.create(:submission, :course => @course, :exercise => @exercise, :user => @user, :requests_review => true)
    Factory.create(:submission_data, :submission => @submission)

    using_session(:user) do
      if Capybara.default_driver == :selenium
        Capybara.current_session.driver.browser.manage.window.resize_to 1250, 900
      end
      visit '/'
      log_in_as @user.username, @user.password
    end

    visit '/'
    log_in_as @admin.username, @admin.password
  end

  after :each do
    log_out # avoid comet auth error msg on the console
  end

  it "should be delivered in the web interface" do
    click_link @course.name
    click_link '1 code review requested'
    click_link 'Requested'
    click_button 'Start code review'
    fill_in 'review_review_body', :with => 'Dude, indent your code!'
    click_button 'Save review'

    using_session(:user) do
      expect(page).to have_content("Your submission for #{@exercise.name} was reviewed.")
    end
  end
end