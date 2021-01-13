# frozen_string_literal: true

require 'spec_helper'

describe ReviewsController, type: :controller do
  before :each do
    @organization = FactoryBot.create :accepted_organization
    @teacher = FactoryBot.create :user
    @admin = FactoryBot.create(:admin)
    @student = FactoryBot.create :user, password: 'foobar'
    Teachership.create! user: @teacher, organization: @organization
  end

  describe 'POST create' do
    before :each do
      @student = FactoryBot.create :user, password: 'foobar'
      @course = FactoryBot.create :course, organization: @organization
      @exercise = FactoryBot.create :exercise, course: @course
      @submission = FactoryBot.create :submission, course: @course, user: @student, exercise: @exercise, requests_review: true
    end

    describe 'As an admin' do
      it 'can make new review' do
        controller.current_user = @admin
        expect do
          post :create, params: { submission_id: @submission.id, review: { review_body: 'Code looks ok' } }
        end.to change(Review, :count).by(1)
        expect(Review.last.review_body).to eq('Code looks ok')
      end
    end

    describe 'As a teacher' do
      it 'can make new review' do
        controller.current_user = @teacher
        expect do
          post :create, params: { submission_id: @submission.id, review: { review_body: 'Code looks ok' } }
        end.to change(Review, :count).by(1)
        expect(Review.last.review_body).to eq('Code looks ok')
      end
    end

    describe 'As a student' do
      it "can't make new review" do
        controller.current_user = @student
        expect do
          post :create, params: { submission_id: @submission.id, review: { review_body: 'Code looks ok' } }
        end.to change(Review, :count).by(0)
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
