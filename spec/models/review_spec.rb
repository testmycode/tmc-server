require 'spec_helper'

describe Review, :type => :model do
  before :each do
    @course = FactoryGirl.create(:course)
    @admin = FactoryGirl.create(:admin)
    @user = FactoryGirl.create(:user)
    @ex = FactoryGirl.create(:exercise, :course => @course)
    AvailablePoint.create(:course => @course, :exercise => @ex, :name => '1')
    AvailablePoint.create(:course => @course, :exercise => @ex, :name => '2')
    @ex.save!
    @sub = FactoryGirl.create(:submission, :course => @course, :exercise_name => @ex.name, :user => @user)
  end

  def mk_review(body = 'This is a review. Of your code.')
    Review.create(:reviewer => @admin, :submission => @sub, :review_body => body)
  end

  describe "associations" do
    specify "to reviewer" do
      review = mk_review
      expect(review.reviewer).to eq(@admin)
      expect(@admin.reviews).to eq([review])
    end
    specify "to submission" do
      review = mk_review
      expect(review.submission).to eq(@sub)
      expect(@sub.reviews).to eq([review])
    end
  end

  it "is not deleted when the reviewing user is destroyed" do
    review = mk_review
    @admin.destroy
    expect(Review.find_by_id(review.id)).not_to be_nil
  end

  it "is deleted when the submission is destroyed" do
    review = mk_review
    @sub.destroy
    expect(Review.find_by_id(review.id)).to be_nil
  end
end
