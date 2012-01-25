require 'test_helper'
require 'rails/performance_test_help'

class SubmissionListTest < ActionDispatch::PerformanceTest
  def test_submission_list_1000
    course = Factory.create(:course)
    user = Factory.create(:user)
    1000.times { Factory.create(:submission, :course => course, :user => user) }
    
    admin = Factory.create(:admin)
    post '/sessions', :session => { :login => admin.login, :password => admin.password }
    
    get "/courses/#{course.id}"
  end
end
