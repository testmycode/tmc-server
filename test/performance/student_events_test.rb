require 'test_helper'
require 'tempfile'
require 'rails/performance_test_help'

class StudentEventsTest < ActionDispatch::PerformanceTest
  EVENTS = 500

  def setup
    @exercise = Factory.create(:exercise)
    @course = @exercise.course
    @user = Factory.create(:user)
    @tempfile = Tempfile.open('tmc-perftest')

    @events = {}
    EVENTS.times do |i|
      @events["ev#{i}"] = make_small_event
    end

    @tempfile.rewind

    post '/sessions', :session => { :login => @user.login, :password => @user.password }
  end

  def teardown
    @tempfile.close
    @tempfile.unlink
  end

  def test_receiving_lots_of_student_events
    uploaded_file = fixture_file_upload(@tempfile.path, 'application/binary')
    class << uploaded_file
      # http://stackoverflow.com/questions/7793510/mocking-file-uploads-in-rails-3-1-controller-tests
      attr_reader :tempfile
    end

    params = {
      :events => @events,
      :api_version => ApplicationController::API_VERSION,
      :data => uploaded_file
    }

    post '/student_events.json', params
    assert(response.successful?)
  end

  def make_small_event
    e = {
      course_name: @course.name,
      exercise_name: @exercise.name,
      event_type: 'text_insert',
      happened_at: '2013-11-04 22:33',
      system_nano_time: 123456789,
      data_offset: @tempfile.length,
      data_length: 3
    }
    @tempfile.write 'asd'
    e
  end
end
