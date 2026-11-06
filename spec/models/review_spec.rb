# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Review, type: :model do
  before :each do
    @course = FactoryBot.create(:course)
    @admin = FactoryBot.create(:admin)
    @user = FactoryBot.create(:user)
    @ex = FactoryBot.create(:exercise, course: @course)
    AvailablePoint.create(course: @course, exercise: @ex, name: '1')
    AvailablePoint.create(course: @course, exercise: @ex, name: '2')
    @ex.save!
    @sub = FactoryBot.create(:submission, course: @course, exercise_name: @ex.name, user: @user)
  end

  def mk_review(body = 'This is a review. Of your code.')
    Review.create(reviewer: @admin, submission: @sub, review_body: body)
  end

  describe 'associations' do
    specify 'to reviewer' do
      review = mk_review
      expect(review.reviewer).to eq(@admin)
      expect(@admin.reviews).to eq([review])
    end
    specify 'to submission' do
      review = mk_review
      expect(review.submission).to eq(@sub)
      expect(@sub.reviews).to eq([review])
    end
  end

  it 'is not deleted when the reviewing user is destroyed' do
    review = mk_review
    @admin.destroy
    expect(Review.find_by(id: review.id)).not_to be_nil
  end

  it 'is deleted when the submission is destroyed' do
    review = mk_review
    @sub.destroy
    expect(Review.find_by(id: review.id)).to be_nil
  end

  describe '.course_reviews_json' do
    let(:view_context) do
      controller = ApplicationController.new
      controller.request = ActionDispatch::TestRequest.create
      controller.view_context
    end

    it "lists no points to award when the review's exercise has been removed" do
      review = mk_review
      @ex.destroy

      json = Review.course_reviews_json(@course, Submission.where(id: @sub.id), view_context)

      expect(json.map { |r| r[:id] }).to eq([review.id])
      expect(json.first[:points_not_awarded]).to eq([])
    end

    it 'lists reviews whose reviewer has been deleted' do
      mk_review
      @admin.destroy

      json = Review.course_reviews_json(@course, Submission.where(id: @sub.id), view_context)

      expect(json.first[:reviewer_name]).to eq('(deleted)')
    end
  end
end
