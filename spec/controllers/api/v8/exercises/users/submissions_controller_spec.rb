# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Exercises::Users::SubmissionsController, type: :controller do
  let(:user) { FactoryBot.create(:verified_user) }
  let(:exercise) { FactoryBot.create(:exercise) }

  def sign_in(as)
    allow(controller).to receive(:doorkeeper_token).and_return(as && double(resource_owner_id: as.id, acceptable?: true))
  end

  def submission(owner, **attributes)
    FactoryBot.create(:submission, user: owner, course: exercise.course, exercise: exercise, **attributes)
  end

  it "lists the user's own submissions of the exercise" do
    own = submission(user)
    submission(FactoryBot.create(:user))
    sign_in(user)
    get :index, params: { exercise_id: exercise.id, user_id: 'current' }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck('id')).to eq([own.id])
  end

  it "does not list another user's submissions to a student" do
    other = FactoryBot.create(:user)
    submission(other)
    sign_in(user)
    get :index, params: { exercise_id: exercise.id, user_id: other.id }
    expect(response.parsed_body).to eq([])
  end

  it 'lists a null paste message as an empty string, which tmc-langs requires' do
    submission(user, message_for_paste: nil)
    sign_in(user)
    get :index, params: { exercise_id: exercise.id, user_id: 'current' }
    expect(response.parsed_body.first['message_for_paste']).to eq('')
  end

  it 'hides the results of an exam-mode exercise without nulling the pass flag' do
    exercise.update!(hide_submission_results: true)
    submission(user, all_tests_passed: true)
    sign_in(user)
    get :index, params: { exercise_id: exercise.id, user_id: 'current' }
    expect(response.parsed_body.first).to include('all_tests_passed' => false, 'points' => nil)
  end

  it 'requires a signed-in user' do
    sign_in(nil)
    get :index, params: { exercise_id: exercise.id, user_id: 'current' }
    expect(response).to have_http_status(:unauthorized)
  end
end
