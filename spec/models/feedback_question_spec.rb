# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe FeedbackQuestion, type: :model do
  it_behaves_like 'an Orderable' do
    def new_record
      FactoryBot.build(:feedback_question)
    end
  end

  describe 'kind' do
    it 'accepts text and integer ranges' do
      expect(FactoryBot.build(:feedback_question, kind: 'text')).to be_valid
      expect(FactoryBot.build(:feedback_question, kind: 'intrange[-5..5]')).to be_valid
    end

    it 'rejects anything else' do
      question = FactoryBot.build(:feedback_question, kind: 'intrange[..]')
      expect(question).not_to be_valid
      expect(question.errors[:kind]).to eq(['invalid'])
    end
  end
end
