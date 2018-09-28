# frozen_string_literal: true

require 'spec_helper'

describe ReviewsController, type: :controller do
  before :each do
    @organization = FactoryGirl.create :accepted_organization
    @teacher = FactoryGirl.create :user
    @admin = FactoryGirl.create(:admin)
    @student = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization
  end

  describe 'POST create' do
    before :each do
      @student = FactoryGirl.create :user, password: 'foobar'
      @course = FactoryGirl.create :course, organization: @organization
      @exercise = FactoryGirl.create :exercise, course: @course
      @submission = FactoryGirl.create :submission, course: @course, user: @student, exercise: @exercise, requests_review: true
    end

    describe 'As an admin' do
      it 'can make new review' do
        controller.current_user = @admin
        expect do
          post :create, submission_id: @submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(1)
        expect(Review.last.review_body).to eq('Code looks ok')
      end
    end

    describe 'As a teacher' do
      it 'can make new review' do
        controller.current_user = @teacher
        expect do
          post :create, submission_id: @submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(1)
        expect(Review.last.review_body).to eq('Code looks ok')
      end
    end

    describe 'As a student' do
      it "can't make new review" do
        controller.current_user = @student
        expect do
          post :create, submission_id: @submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(0)
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
