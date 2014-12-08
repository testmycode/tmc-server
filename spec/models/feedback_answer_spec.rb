require 'spec_helper'

describe FeedbackAnswer, :type => :model do
  it "should not be destroyed when its submission is destroyed" do
    answer = FactoryGirl.create(:feedback_answer)
    answer.submission.destroy
    answer.reload
    expect(answer.submission).to be_nil
  end
end
