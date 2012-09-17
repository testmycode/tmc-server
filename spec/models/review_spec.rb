require 'spec_helper'

describe Review do
  before :each do
    @course = Factory.create(:course)
    @admin = Factory.create(:admin)
    @user = Factory.create(:user)
    @ex = Factory.create(:exercise, :course => @course)
    AvailablePoint.create(:course => @course, :exercise => @ex, :name => '1')
    AvailablePoint.create(:course => @course, :exercise => @ex, :name => '2')
    @ex.save!
    @sub = Factory.create(:submission, :course => @course, :exercise_name => @ex.name, :user => @user)
  end

  def mk_review(body = 'This is a review. Of your code.')
    Review.create(:reviewer => @admin, :submission => @sub, :review_body => body)
  end

  describe "associations" do
    specify "to reviewer" do
      review = mk_review
      review.reviewer.should == @admin
      @admin.reviews.should == [review]
    end
    specify "to submission" do
      review = mk_review
      review.submission.should == @sub
      @sub.reviews.should == [review]
    end
  end

  it "is not deleted when the reviewing user is destroyed" do
    review = mk_review
    @admin.destroy
    Review.find_by_id(review.id).should_not be_nil
  end

  it "is deleted when the submission is destroyed" do
    review = mk_review
    @sub.destroy
    Review.find_by_id(review.id).should be_nil
  end
end
