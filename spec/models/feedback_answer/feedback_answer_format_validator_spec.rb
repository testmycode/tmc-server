# frozen_string_literal: true

require 'spec_helper'

describe Validators::FeedbackAnswerFormatValidator, type: :model do
  it 'should validate integer ranges' do
    answer = FactoryBot.create(:feedback_answer)
    answer.feedback_question.kind = 'intrange[-5..5]'

    answer.answer = '3'
    expect(answer).to be_valid
    answer.answer = '1'
    expect(answer).to be_valid
    answer.answer = '-1'
    expect(answer).to be_valid
    answer.answer = '5'
    expect(answer).to be_valid
    answer.answer = '-5'
    expect(answer).to be_valid

    answer.answer = '-6'
    expect(answer).not_to be_valid
    answer.answer = '6'
    expect(answer).not_to be_valid
    answer.answer = '1.1'
    expect(answer).not_to be_valid
    answer.answer = 'foo'
    expect(answer).not_to be_valid
    answer.answer = ''
    expect(answer).not_to be_valid
  end

  it 'should accept non-empty text answers' do
    answer = FactoryBot.create(:feedback_answer)
    answer.feedback_question.kind = 'text'

    answer.answer = 'foo'
    expect(answer).to be_valid

    answer.answer = ''
    expect(answer).not_to be_valid
    answer.answer = ' '
    expect(answer).not_to be_valid
  end

  it 'should not anything when question kind is invalid' do
    answer = FactoryBot.create(:feedback_answer)
    answer.feedback_question.kind = 'an invalid kind'

    answer.answer = 'foo'
    expect(answer).not_to be_valid
  end
end
