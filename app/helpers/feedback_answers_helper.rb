# typed: strict
# frozen_string_literal: true

module FeedbackAnswersHelper
  extend T::Sig
  sig { params(answer: FeedbackAnswer).returns(String) }
  def render_feedback_answer(answer)
    question = T.must(answer.feedback_question)
    if question.intrange?
      answer.answer + '/' + question.intrange.max.to_s
    else
      simple_format(answer.answer)
    end
  end

  sig { params(action: String, answer: FeedbackAnswer).returns(String) }
  def name_for(action, answer)
    "#{action} #{pluralize(answer.reply_to_feedback_answers.count, 'reply').sub(/\d+\s/, '')}"
  end
end
