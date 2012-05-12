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

    params = {
      :format => :json,
      :api_version => ApplicationController::API_VERSION,
      :events => events.map do |e|
        {:exercise_name => @exercise.name, :course_name => @course.name}.merge(e)
      end,
      :data => file
    }.merge(params)

    post :create, params
  end

  it "should store log events" do

    data = 'foobar' + 'barfooxoo'
    events = [
      {:event_type => 'code_snapshot', :data_offset => 0, :data_length => 6, :happened_at => '2012-02-02 02:02'},
      {:event_type => 'code_snapshot', :data_offset => 6, :data_length => 9, :happened_at => '2013-03-03 03:03'}
    ]
    post_log(events, data)
    response.should be_successful

    StudentEvent.count.should == 2
    StudentEvent.first.event_type.should == 'code_snapshot'
    StudentEvent.first.data.should == 'foobar'
    StudentEvent.first.happened_at.should == Time.parse('2012-02-02 02:02')
    StudentEvent.last.event_type.should == 'code_snapshot'
    StudentEvent.last.data.should == 'barfooxoo'
    StudentEvent.last.happened_at.should == Time.parse('2013-03-03 03:03')
  end
end