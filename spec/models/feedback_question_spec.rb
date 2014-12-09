require 'spec_helper'

describe FeedbackQuestion, type: :model do
  it_behaves_like "an Orderable" do
    def new_record
      FactoryGirl.build(:feedback_question)
    end
  end
end