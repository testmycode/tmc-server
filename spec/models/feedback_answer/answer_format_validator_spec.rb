require 'spec_helper'

describe FeedbackAnswer::AnswerFormatValidator do
  it "should validate integer ranges" do
    answer = Factory.create(:feedback_answer)
    answer.question.kind = 'intrange[-5..5]'
    
    answer.answer = '3'
    answer.should be_valid
    answer.answer = '1'
    answer.should be_valid
    answer.answer = '-1'
    answer.should be_valid
    answer.answer = '5'
    answer.should be_valid
    answer.answer = '-5'
    answer.should be_valid
    
    answer.answer = '-6'
    answer.should_not be_valid
    answer.answer = '6'
    answer.should_not be_valid
    answer.answer = '1.1'
    answer.should_not be_valid
    answer.answer = 'foo'
    answer.should_not be_valid
    answer.answer = ''
    answer.should_not be_valid
  end
  
  it "should accept non-empty text answers" do
    answer = Factory.create(:feedback_answer)
    answer.question.kind = 'text'
    
    answer.answer = 'foo'
    answer.should be_valid
    
    answer.answer = ''
    answer.should_not be_valid
    answer.answer = ' '
    answer.should_not be_valid
  end
  
  it "should not anything when question kind is invalid" do
    answer = Factory.create(:feedback_answer)
    answer.question.kind = 'an invalid kind'
    
    answer.answer = 'foo'
    answer.should_not be_valid
  end
end
