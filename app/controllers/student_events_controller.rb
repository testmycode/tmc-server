
# Receives "spyware" events from the IDE.
class StudentEventsController < ApplicationController
  def create
    user = current_user
    authorize! :create, StudentEvent

    event_records = params['events'].values

    inserts = []
    #events = []
    File.open(params['data'].tempfile.path, 'rb') do |data_file|
      ActiveRecord::Base.connection.transaction(:requires_new => true) do
        event_records.each do |record|

          event_type = record['event_type']
          metadata = record['metadata']
          happened_at = record['happened_at']
          system_nano_time = record['system_nano_time']

          data_file.pos = record['data_offset'].to_i
          data = data_file.read(record['data_length'].to_i)

          check_json_syntax(metadata) if metadata
          metadata = "" if metadata.blank?
          data = "" if data.blank?
          # inserts << "(user.id, record['course_name'], record['exercise_name'], event_type, metadata, data, happened_at, system_nano_time)"

          #event = StudentEvent.new(

          event = {
            :user_id => user.id,
            :course_name => record['course_name'],
            :exercise_name => record['exercise_name'],
            :event_type => event_type,
            :metadata_json => metadata,
            :data => data,
            :happened_at => happened_at,
            :system_nano_time => system_nano_time
          }
          inserts << "('#{event.values.join("','")}')"#.gsub('"', "'")
          #)
          #events << event
          #if events.size > 30
          #  StudentEvent.import events.shift(30)
          #end
          #event.save!
        end
        #StudentEvent.import events
        #
        sql = "INSERT INTO student_events (user_id, course_name, exercise_name, event_type, metadata_json, data, happened_at, system_nano_time) VALUES #{inserts.join(', ')}"
#        puts "#{'*'* 200}"
#        puts sql
#        puts "#{'*'* 200}"
        StudentEvent.connection.execute sql
      end
    end

    respond_to do |format|
      format.json do
        render :json => {:status => 'ok'}
      end
    end
  end

  private

  def check_json_syntax(string)
    ActiveSupport::JSON.decode(string)
    nil
  end

end
