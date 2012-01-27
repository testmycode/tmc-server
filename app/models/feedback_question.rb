class FeedbackQuestion < ActiveRecord::Base
  belongs_to :course
  has_many :feedback_answers
end
