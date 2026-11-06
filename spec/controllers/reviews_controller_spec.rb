# typed: false
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

  describe 'GET index for a course as JSON' do
    before :each do
      @course = FactoryBot.create :course, organization: @organization
      @exercise = FactoryBot.create :exercise, course: @course
      @submission = FactoryBot.create :submission, course: @course, user: @student, exercise: @exercise, reviewed: true
      @review = FactoryBot.create :review, submission: @submission, reviewer: @teacher
      controller.current_user = @student
    end

    it 'labels reviews whose reviewer has been deleted' do
      @review.update_column(:reviewer_id, nil)

      get :index, params: { organization_id: @organization.slug, course_id: @course.id, format: :json, api_version: ApiVersion::API_VERSION }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['reviews'].map { |r| r['reviewer_name'] }).to eq(['(deleted)'])
    end

    it 'lists reviews of exercises that have been removed' do
      @exercise.update_column(:name, 'removed-by-refresh')

      get :index, params: { organization_id: @organization.slug, course_id: @course.id, format: :json, api_version: ApiVersion::API_VERSION }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['reviews'].map { |r| r['points_not_awarded'] }).to eq([[]])
    end

    it 'responds 404 to the review page of a submission whose exercise has been removed' do
      FactoryBot.create(:submission_data, submission: @submission)
      @exercise.update_column(:name, 'removed-by-refresh')

      get :index, params: { submission_id: @submission.id }

      expect(response).to have_http_status(:not_found)
    end
  end
end
