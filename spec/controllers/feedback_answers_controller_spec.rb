# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe FeedbackAnswersController, type: :controller do
  before :each do
    @exercise = FactoryGirl.create(:exercise)
    @course = @exercise.course
    @user = FactoryGirl.create(:user)
    @submission = FactoryGirl.create(:submission, course: @course, exercise: @exercise, user: @user)
    @q1 = FactoryGirl.create(:feedback_question, kind: 'text', course: @course)
    @q2 = FactoryGirl.create(:feedback_question, kind: 'intrange[1..5]', course: @course)

    controller.current_user = @submission.user
  end

  describe '#create' do
    before :each do
      @valid_params = {
        submission_id: @submission.id,
        answers: [
          { question_id: @q1.id, answer: 'foobar' },
          { question_id: @q2.id, answer: '3' }
        ],
        format: :json,
        api_version: ApiVersion::API_VERSION
      }
    end

    it "should accept answers to all questions associated to the submission's course at once" do
      post :create, @valid_params

      expect(response).to be_successful

      answers = FeedbackAnswer.order(:feedback_question_id)
      expect(answers.count).to eq(2)
      expect(answers[0].feedback_question_id).to eq(@q1.id)
      expect(answers[1].feedback_question_id).to eq(@q2.id)
      expect(answers[0].answer).to eq('foobar')
      expect(answers[1].answer).to eq('3')
    end

    it 'should not save any answers and return withan error if even one answer is invalid' do
      params = @valid_params.clone
      params[:answers][1][:answer] = 'something invalid'

      post :create, params

      expect(response).not_to be_successful
      expect(FeedbackAnswer.all.count).to eq(0)
    end

    it 'should not allow answering on behalf of another user' do
      bypass_rescue

      another_user = FactoryGirl.create(:user)
      another_submission = FactoryGirl.create(:submission, course: @course, exercise: @exercise, user: another_user)
      params = @valid_params.clone
      params[:submission_id] = another_submission.id

      # Convert params to FeedbackAnswers
      answer_params = params[:answers]
      answer_params = answer_params.values if answer_params.respond_to?(:values)

      answer_records = answer_params.map do |answer_hash|
        FeedbackAnswer.new(submission: @submission,
                           course_id: @submission.course_id,
                           exercise_name: @submission.exercise_name,
                           feedback_question_id: answer_hash[:question_id],
                           answer: answer_hash[:answer])
      end

      ability = Ability.new(another_user)
      expect(ability).to be_able_to(:read, another_submission)

      # Check if user can create FeedbackAnswer to submission
      answer_records.each { |record| expect(ability).not_to be_able_to(:create, record) }

      expect { post :create, params }.to raise_error(CanCan::AccessDenied)
    end
  end
end
