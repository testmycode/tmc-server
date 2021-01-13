# frozen_string_literal: true

require 'spec_helper'

describe FeedbackAnswer, type: :model do
  it 'should not be destroyed when its submission is destroyed' do
    answer = FactoryBot.create(:feedback_answer)
    answer.submission.destroy
    answer.reload
    expect(answer.submission).to be_nil
  end
end
