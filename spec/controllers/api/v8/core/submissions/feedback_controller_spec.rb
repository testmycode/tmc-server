require 'spec_helper'

describe Api::V8::Core::Submissions::FeedbackController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:student) { FactoryGirl.create(:user) }
  let!(:course) { FactoryGirl.create(:course, organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) { FactoryGirl.create(:submission, course: course, user: student, exercise: exercise, requests_review: true) }
  let(:question) { FactoryGirl.create(:feedback_question, course: course) }

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'POST create' do
    describe 'As a student' do
      let(:token) { double resource_owner_id: student.id, acceptable?: true }

      it 'can give feedback' do
        expect do
          post :create, params: { submission_id: submission.id, answers: [{ answer: '2', question_id: question.id }] }
        end.to change(FeedbackAnswer, :count).by(1)
        expect(response.code.to_i).to eq(302)
      end
    end

    describe 'As an unauthenticated user' do
      let(:token) { nil }

      it "can't give feedback" do
        expect do
          post :create, params: { submission_id: submission.id, answers: [{ answer: '2', question_id: question.id }] }
        end.to change(FeedbackAnswer, :count).by(0)
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
