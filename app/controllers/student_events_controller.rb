require 'student_event_factory'

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
          happened_at = record['happened_at']

          data_file.pos = record['data_offset'].to_i
          data = data_file.read(record['data_length'].to_i)

          event = StudentEventFactory.create_event(user, exercise, event_type, data, happened_at)
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
end
