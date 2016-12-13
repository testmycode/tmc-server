require 'spec_helper'

describe Api::V8::Core::Courses::ReviewsController, type: :controller do
  let(:user2) { FactoryGirl.create(:user) }
  let(:course) { FactoryGirl.create(:course) }
  let(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let(:submission) { FactoryGirl.create(:submission, exercise: exercise, course: course, user: user, reviewed: true) }
  let(:submission2) { FactoryGirl.create(:submission, exercise: exercise, course: course, user: user2, reviewed: true) }
  let!(:review) { FactoryGirl.create(:review, reviewer: user, submission: submission) }
  let!(:submission2_review) { FactoryGirl.create(:review, review_body: "submission2_review body", submission: submission2) }

  before(:each) do
    controller.stub(:doorkeeper_token) { token }
  end

  describe "GET reviews for a course for current user's submissions" do
    describe 'as admin' do
      let(:user) { FactoryGirl.create(:admin) }
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      describe 'when course id given' do
        it "shows only user's submission's review information" do
          get :index, course_id: course.id
          expect(response).to have_http_status(:success)
          json = JSON.parse response.body
          json[0]["submission_id"].should == review.submission.id
          json[0]["exercise_name"].should == exercise.name
          json[0]["id"].should == review.id
          json[0]["reviewer_name"].should == user.username
          json[0]["review_body"].should == review.review_body
          expect(response.body).not_to include submission2_review.review_body
        end
      end
      describe 'when invalid course id given' do
        it 'shows error about finding course' do
          get :index, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include review.review_body
          expect(response.body).not_to include submission2_review.review_body
        end
      end
    end

    describe 'as user' do
      let(:user) { FactoryGirl.create(:user) }
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      describe 'when course id given' do
        it "shows only user's submission's review information" do
          get :index, course_id: course.id
          expect(response).to have_http_status(:success)
          json = JSON.parse response.body
          json[0]["submission_id"].should == review.submission.id
          json[0]["exercise_name"].should == exercise.name
          json[0]["id"].should == review.id
          json[0]["reviewer_name"].should == user.username
          json[0]["review_body"].should == review.review_body
          expect(response.body).not_to include submission2_review.review_body
        end
      end
      describe 'when invalid course id given' do
        it 'shows error about finding course' do
          get :index, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include review.review_body
          expect(response.body).not_to include submission2_review.review_body
        end
      end
    end

    describe 'as guest' do
      let(:user) { Guest.new }
      let(:token) { nil }

      describe 'when course id given' do
        it "shows only user's submission's review information" do
          get :index, course_id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to include "Authentication required"
          expect(response.body).not_to include review.review_body
          expect(response.body).not_to include submission2_review.review_body
        end
      end
      describe 'when invalid course id given' do
        it 'shows error about finding course' do
          get :index, course_id: -1
          expect(response).to have_http_status(403)
          expect(response.body).to include "Authentication required"
          expect(response.body).not_to include review.review_body
          expect(response.body).not_to include submission2_review.review_body
        end
      end
    end
  end
end
