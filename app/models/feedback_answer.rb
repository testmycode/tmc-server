class FeedbackAnswer < ActiveRecord::Base
  belongs_to :feedback_question
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }
  belongs_to :submission

  validates_with Validators::FeedbackAnswerFormatValidator
end
