require 'spec_helper'

describe Api::V8::Core::Submissions::ReviewsController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:teacher) { FactoryGirl.create(:user) }
  let!(:admin) { FactoryGirl.create(:admin) }
  let!(:student) { FactoryGirl.create(:user) }
  let!(:course) { FactoryGirl.create(:course, organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) { FactoryGirl.create(:submission, course: course, user: student, exercise: exercise, requests_review: true) }

  before :each do
    Teachership.create! user: teacher, organization: organization
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST create' do
    describe 'As an admin' do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }

      it 'can make new review' do
        expect do
          post :create, submission_id: submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(1)
        expect(Review.last.review_body).to eq('Code looks ok')
      end
    end

    describe 'As a teacher' do
      let(:token) { double resource_owner_id: teacher.id, acceptable?: true }

      it 'can make new review' do
        expect do
          post :create, submission_id: submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(1)
        expect(Review.last.review_body).to eq('Code looks ok')
      end
    end

    describe 'As a student' do
      let(:token) { double resource_owner_id: student.id, acceptable?: true }

      it "can't make new review" do
        expect do
          post :create, submission_id: submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(0)
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'As an unauthenticated user' do
      let(:token) { nil }

      it "can't make new review" do
        expect do
          post :create, submission_id: submission.id, review: { review_body: 'Code looks ok' }
        end.to change(Review, :count).by(0)
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
