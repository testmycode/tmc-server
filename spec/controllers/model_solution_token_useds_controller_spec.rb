# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe ModelSolutionTokenUsedsController, type: :controller do
  render_views

  let(:token_used) do
    ModelSolutionTokenUsed.create!(user: FactoryBot.create(:user), course: FactoryBot.create(:course), exercise_name: 'ex1')
  end

  it 'shows token uses to admins' do
    controller.current_user = FactoryBot.create(:admin)

    get :index
    expect(response).to be_successful
    get :show, params: { id: token_used.id }
    expect(response).to be_successful
  end

  it 'forbids other users' do
    controller.current_user = FactoryBot.create(:user)

    get :index
    expect(response).to have_http_status(:forbidden)
    get :show, params: { id: token_used.id }
    expect(response).to have_http_status(:forbidden)
  end
end
