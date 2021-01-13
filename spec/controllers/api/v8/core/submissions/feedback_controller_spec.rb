# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::Submissions::FeedbackController, type: :controller do
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:student) { FactoryBot.create(:user) }
  let!(:course) { FactoryBot.create(:course, organization: organization) }
  let!(:exercise) { FactoryBot.create(:exercise, course: course) }
  let!(:submission) { FactoryBot.create(:submission, course: course, user: student, exercise: exercise, requests_review: true) }
  let(:question) { FactoryBot.create(:feedback_question, course: course) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST create' do
    describe 'As a student' do
      let(:token) { double resource_owner_id: student.id, acceptable?: true }

      it 'can give feedback' do
        # pending 'Failing for some reason'
        expect {
          post :create, params: { submission_id: submission.id, answers: [{ answer: '2', question_id: question.id }] }
        }.to change(FeedbackAnswer, :count).by(1)
        expect(response.code.to_i).to eq(302)
      end
    end

    describe 'As an unauthenticated user' do
      let(:token) { nil }

      it "can't give feedback" do
        # pending 'Failing for some reason'
        expect do
          post :create, params: { submission_id: submission.id, answers: [{ answer: '2', question_id: question.id }] }
        end.to change(FeedbackAnswer, :count).by(0)
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
