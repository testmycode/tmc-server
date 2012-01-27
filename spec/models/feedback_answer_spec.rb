require 'spec_helper'

describe FeedbackAnswer do
  it "should not be destroyed when its submission is destroyed" do
    answer = Factory.create(:feedback_answer)
    answer.submission.destroy
    answer.reload
    answer.submission.should be_nil
  end
end
