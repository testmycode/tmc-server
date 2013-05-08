
# A logged data point from the IDE's "spyware".
class StudentEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
      :conditions => proc { "exercises.course_id = #{self.course_id}" }

  def self.supported_event_types
    ['code_snapshot', 'project_action', 'text_insert', 'text_remove']
  end
end