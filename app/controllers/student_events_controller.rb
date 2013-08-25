
# Receives "spyware" events from the IDE.
class StudentEventsController < ApplicationController
  def create
    user = current_user

    event_records = params['events'].values

    File.open(params['data'].tempfile.path, 'rb') do |data_file|
      ActiveRecord::Base.connection.transaction(:requires_new => true) do
        for record in event_records
          course = Course.find_by_name!(record['course_name'])
          exercise = course.exercises.find_by_name!(record['exercise_name'])
          authorize! :read, exercise

          event_type = record['event_type']
          metadata = record['metadata']
          happened_at = record['happened_at']
          system_nano_time = record['system_nano_time']

          data_file.pos = record['data_offset'].to_i
          data = data_file.read(record['data_length'].to_i)

          unless StudentEvent.supported_event_types.include?(event_type)
            raise "Invalid event type: '#{event_type}'"
          end

          check_json_syntax(metadata) if metadata

          event = StudentEvent.new(
            :user_id => user.id,
            :course_id => exercise.course_id,
            :exercise_name => exercise.name,
            :event_type => event_type,
            :metadata_json => metadata,
            :data => data,
            :happened_at => happened_at,
            :system_nano_time => system_nano_time
          )
          authorize! :create, event
          event.save!
        end
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
