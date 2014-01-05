require 'spec_helper'

describe FeedbackAnswersController do
  before :each do
    @exercise = Factory.create(:exercise)
    @course = @exercise.course
    @user = Factory.create(:user)
    @submission = Factory.create(:submission, :course => @course, :exercise => @exercise, :user => @user)
    @q1 = Factory.create(:feedback_question, :kind => 'text', :course => @course)
    @q2 = Factory.create(:feedback_question, :kind => 'intrange[1..5]', :course => @course)

    controller.current_user = @submission.user
  end

  describe "#create" do
    before :each do
      @valid_params = {
        :submission_id => @submission.id,
        :answers => [
          { :question_id => @q1.id, :answer => 'foobar' },
          { :question_id => @q2.id, :answer => '3' }
        ],
        :format => :json,
        :api_version => ApiVersion::API_VERSION
      }
    end

    it "should accept answers to all questions associated to the submission's course at once" do
      post :create, @valid_params

      response.should be_successful

      answers = FeedbackAnswer.order(:feedback_question_id)
      answers.count.should == 2
      answers[0].feedback_question_id.should == @q1.id
      answers[1].feedback_question_id.should == @q2.id
      answers[0].answer.should == 'foobar'
      answers[1].answer.should == '3'
    end

    it "should not save any answers and return withan error if even one answer is invalid" do
      params = @valid_params.clone
      params[:answers][1][:answer] = 'something invalid'

      post :create, params

      response.should_not be_successful
      FeedbackAnswer.all.count.should == 0
    end

    it "should not allow answering on behalf of another user" do
      another_user = Factory.create(:user)
      another_submission = Factory.create(:submission, :course => @course, :exercise => @exercise, :user => another_user)
      params = @valid_params.clone
      params[:submission_id] = another_submission.id

      expect { post :create, params }.to raise_error
    end
  end
end
