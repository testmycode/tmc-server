
class FeedbackAnswer < ActiveRecord::Base
  require 'feedback_answer/answer_format_validator'
  
  belongs_to :feedback_question
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }
  belongs_to :user
  belongs_to :submission
  
  def question
    feedback_question
  end
  
  validates_with AnswerFormatValidator
end

