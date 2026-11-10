# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Exercises::ModelSolutionsController, type: :controller do
  let(:organization) { FactoryBot.create(:accepted_organization) }
  let(:course) { FactoryBot.create(:course, organization: organization) }
  let(:exercise) { FactoryBot.create(:exercise, course: course) }
  let(:student) { FactoryBot.create(:verified_user) }

  before do
    allow_any_instance_of(Solution).to receive(:files).and_return([])
  end

  def sign_in(as)
    allow(controller).to receive(:doorkeeper_token).and_return(double(resource_owner_id: as.id, acceptable?: true))
  end

  def complete_exercises(count)
    FactoryBot.create_list(:exercise, count, course: course).each do |ex|
      FactoryBot.create(:submission, user: student, course: course, exercise: ex, all_tests_passed: true)
    end
  end

  it 'gives a teacher the solution and logs the access' do
    teacher = FactoryBot.create(:verified_user)
    Teachership.create!(user: teacher, organization: organization)
    sign_in(teacher)
    get :index, params: { exercise_id: exercise.id }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('exercise' => { 'id' => exercise.id }, 'solution' => { 'files' => [] })
    expect(ModelSolutionAccessLog.where(user: teacher, exercise_name: exercise.name).count).to eq(1)
  end

  it 'refuses a student who has not earned the solution' do
    sign_in(student)
    get :index, params: { exercise_id: exercise.id }
    expect(response).to have_http_status(:forbidden)
    expect(ModelSolutionAccessLog.count).to eq(0)
  end

  it 'spends a token the student earned, and spends it only once' do
    course.update!(grant_model_solution_token_every_nth_completed_exercise: 2)
    complete_exercises(2)
    sign_in(student)
    2.times do
      get :index, params: { exercise_id: exercise.id }
      expect(response).to have_http_status(:ok)
    end
    expect(ModelSolutionTokenUsed.where(user: student, exercise_name: exercise.name).count).to eq(1)
  end

  it 'refuses a student whose tokens are spent' do
    course.update!(grant_model_solution_token_every_nth_completed_exercise: 2)
    complete_exercises(2)
    ModelSolutionTokenUsed.create!(user: student, course: course, exercise_name: 'another', cost: 1)
    sign_in(student)
    get :index, params: { exercise_id: exercise.id }
    expect(response).to have_http_status(:forbidden)
  end
end
