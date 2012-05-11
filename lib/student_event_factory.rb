module StudentEventFactory
  def self.create_event(user, exercise, event_type, data, happened_at)
    if !StudentEvent.supported_event_types.include?(event_type)
      raise "Invalid event type: '#{event_type}'"
    end

    StudentEvent.new(
      :user_id => user.id,
      :course_id => exercise.course_id,
      :exercise_name => exercise.name,
      :event_type => event_type,
      :data => data,
      :happened_at => happened_at
    )
  end
end