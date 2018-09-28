# frozen_string_literal: true

class ReplyToFeedbackAnswer < ActiveRecord::Base
  belongs_to :feedback_answer
end
