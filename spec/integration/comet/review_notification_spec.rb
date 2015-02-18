require 'spec_helper'

# TODO: cometd gives warnings like the following during this test:
# WARN:oejws.WebSocketServerFactory:qtp466002798-26: Client 127.0.0.1 (:46822) User Agent: [unset] requested WebSocket version [-1], Jetty supports version: [13]
# WARN:oejh.HttpParser:qtp466002798-19: badMessage: 400 Illegal character 0x93 in state=METHOD in 'GET /comet HTTP/1...4 \\ 8\r\n\r\n$<[m>\x93<<<\x06\xAb>>>n/json;charset=UT...\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' for HttpChannelOverHttp@5dd3a532{r=1,c=false,a=IDLE,uri=-}
#
# http://stackoverflow.com/questions/18888055/testing-pusher-with-capybara-poltergeist suggests that
# Poltergeist/PhantomJS may have problems with WebSockets.
#
# This test is commented out for now as of 2015-01-18. It should be retried with a newer (> 1.5.1)
# Poltergeist when available.
#
# The functionality was last tested manually on 2015-01-18.
#
# describe "Notifications about new code reviews via HTTP push", type: :request, integration: true do
#   include IntegrationTestActions
#
#   before :each do
#     CometSupport.ensure_started!
#
#     @admin = FactoryGirl.create(:admin)
#     @user = FactoryGirl.create(:user)
#     @course = FactoryGirl.create(:course)
#     @exercise = FactoryGirl.create(:exercise, course: @course)
#     @submission = FactoryGirl.create(:submission, course: @course, exercise: @exercise, user: @user, requests_review: true)
#     FactoryGirl.create(:submission_data, submission: @submission)
#
#     using_session(:user) do
#       if Capybara.default_driver == :selenium
#         Capybara.current_session.driver.browser.manage.window.resize_to 1250, 900
#       end
#       visit '/'
#       log_in_as @user.username, @user.password
#     end
#
#     visit '/'
#     log_in_as @admin.username, @admin.password
#   end
#
#   after :each do
#     log_out # avoid comet auth error msg on the console
#   end
#
#   it "should be delivered in the web interface" do
#     click_link @course.name
#     click_link '1 code review requested'
#     click_link 'Requested'
#     click_button 'Start code review'
#     fill_in 'review_review_body', with: 'Dude, indent your code!'
#     click_button 'Save review'
#
#     using_session(:user) do
#       expect(page).to have_content("Your submission for #{@exercise.name} was reviewed.")
#     end
#   end
# end
