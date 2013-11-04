require 'test_helper'
require 'tempfile'
require 'rails/performance_test_help'

class StudentEventsTest < ActionDispatch::PerformanceTest
  SMALL_EVENTS = 500
  LARGE_EVENTS = 100

  def setup
    @exercise = Factory.create(:exercise)
    @course = @exercise.course
    @user = Factory.create(:user)
    @small_file = Tempfile.open('tmc-perftest')
    @large_file = Tempfile.open('tmc-perftest')

    @small_events = {}
    SMALL_EVENTS.times do |i|
      @small_events["ev#{i}"] = make_small_event
    end

    @large_events = {}
    LARGE_EVENTS.times do |i|
      @large_events["ev#{i}"] = make_large_event
    end

    @small_file.rewind
    @large_file.rewind

    post '/sessions', :session => { :login => @user.login, :password => @user.password }
  end

  def uploaded_file(tempfile)
    f = fixture_file_upload(tempfile.path, 'application/binary')
    class << f
      # http://stackoverflow.com/questions/7793510/mocking-file-uploads-in-rails-3-1-controller-tests
      attr_reader :tempfile
    end
    f
  end

  def teardown
    @small_file.close
    @small_file.unlink
    @large_file.close
    @large_file.unlink
  end

  def test_receiving_lots_of_student_events
    params = {
      :events => @small_events,
      :api_version => ApplicationController::API_VERSION,
      :data => uploaded_file(@small_file)
    }

    post '/student_events.json', params
    assert(response.successful?)
  end

  def test_receiving_large_student_events
    params = {
      :events => @large_events,
      :api_version => ApplicationController::API_VERSION,
      :data => uploaded_file(@large_file)
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
      data_offset: @small_file.length,
      data_length: 3
    }
    @small_file.write 'asd'
    e
  end

  def make_large_event
    e = {
      course_name: @course.name,
      exercise_name: @exercise.name,
      metadata: {trol: [1,2,3] * 20}.to_json,
      event_type: 'text_insert',
      happened_at: '2013-11-04 22:33',
      system_nano_time: 123456789,
      data_offset: @large_file.length,
      data_length: 1.megabyte
    }
    @large_file.write 'a' * 1.megabyte
    e
  end
end
