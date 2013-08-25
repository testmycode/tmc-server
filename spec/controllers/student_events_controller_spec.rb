require 'spec_helper'

describe StudentEventsController do
  before :each do
    @user = Factory.create(:user)
    @exercise = Factory.create(:exercise)
    @course = @exercise.course

    controller.current_user = @user
  end

  def post_log(events, data, params = {})
    File.open('datafile', 'wb') {|f| f.write(data) }
    file = fixture_file_upload('datafile')
    class << file # See http://stackoverflow.com/questions/7793510/mocking-file-uploads-in-rails-3-1-controller-tests
      attr_reader :tempfile
    end

    events_hash = {}
    events.each_with_index do |e, i|
      events_hash[i.to_s] = {
        :exercise_name => @exercise.name,
        :course_name => @course.name
      }.merge(e)
    end

    params = {
      :format => :json,
      :api_version => ApplicationController::API_VERSION,
      :events => events_hash,
      :data => file
    }.merge(params)

    post :create, params
  end

  it "should store basic student events" do
    data = 'foobar' + 'barfooxoo'
    events = [
      {:event_type => 'code_snapshot', :data_offset => 0, :data_length => 6, :happened_at => '2012-02-02 02:02'},
      {:event_type => 'code_snapshot', :data_offset => 6, :data_length => 9, :happened_at => '2013-03-03 03:03'}
    ]
    post_log(events, data)
    response.should be_successful

    StudentEvent.count.should == 2

    events = StudentEvent.order('happened_at').all

    events.first.course_id.should == @course.id
    events.first.exercise_name.should == @exercise.name
    
    events.first.event_type.should == 'code_snapshot'
    events.first.data.should == 'foobar'
    events.first.happened_at.should == Time.parse('2012-02-02 02:02')
    events.first.metadata.should == nil
    
    events.last.event_type.should == 'code_snapshot'
    events.last.data.should == 'barfooxoo'
    events.last.happened_at.should == Time.parse('2013-03-03 03:03')
    events.last.metadata.should == nil
  end

  it "should store optional fields if given" do
    data = 'foobar' + 'barfooxoo'
    events = [
      {
        :event_type => 'code_snapshot',
        :data_offset => 0,
        :data_length => 6,
        :happened_at => '2012-02-02 02:02',
        :system_nano_time => 123456789123456789,
        :metadata => '{"asd": "bsd"}'
      }
    ]
    post_log(events, data)
    response.should be_successful

    StudentEvent.count.should == 1
    StudentEvent.first.metadata.should == {'asd' => 'bsd'}
    StudentEvent.first.system_nano_time.should == 123456789123456789
  end
end
