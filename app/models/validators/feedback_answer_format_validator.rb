# frozen_string_literal: true

class Validators::FeedbackAnswerFormatValidator < ActiveModel::Validator
  def validate(record)
    kind = record.feedback_question.kind
    ans = record.answer.strip
    errors = record.errors[:answer]

    if kind =~ FeedbackQuestion.send(:intrange_regex)
      range = (Regexp.last_match(1).to_i)..(Regexp.last_match(2).to_i)
      if !/^(-?\d+)$/.match?(ans)
        errors << 'is not an integer'
      elsif !range.include?(ans.to_i)
        errors << "is not between #{range.first}..#{range.last}"
      end
    elsif kind == 'text'
      errors << 'empty' if ans.blank?
    else
      errors << "unacceptable since question type '#{kind}' is unknown"
    end
  end
end
