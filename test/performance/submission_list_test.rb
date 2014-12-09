require 'test_helper'
require 'rails/performance_test_help'

class SubmissionListTest < ActionDispatch::PerformanceTest
  def test_submission_list_200
    course = FactoryGirl.create(:course)
    user = FactoryGirl.create(:user)
    200.times { FactoryGirl.create(:submission, course: course, user: user) }

    admin = FactoryGirl.create(:admin)
    post '/sessions', session: { login: admin.login, password: admin.password }

    get "/courses/#{course.id}"
  end
end
