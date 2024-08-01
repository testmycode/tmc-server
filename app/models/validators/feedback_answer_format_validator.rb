# frozen_string_literal: true

class Validators::FeedbackAnswerFormatValidator < ActiveModel::Validator
  def validate(record)
    kind = record.feedback_question.kind
    ans = record.answer.strip

    if kind =~ FeedbackQuestion.send(:intrange_regex)
      range = (Regexp.last_match(1).to_i)..(Regexp.last_match(2).to_i)
      if !/^(-?\d+)$/.match?(ans)
        record.errors.add(:answer, 'is not an integer')
      elsif !range.include?(ans.to_i)
        record.errors.add(:answer, "is not between #{range.first}..#{range.last}")
      end
    elsif kind == 'text'
      record.errors.add(:answer, 'empty') if ans.blank?
    else
      record.errors.add(:answer, "unacceptable since question type '#{kind}' is unknown")
    end
  end
end
