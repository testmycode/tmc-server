# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe FullZipController, type: :controller do
  it 'responds 404 when the submission\'s exercise has been removed' do
    submission = FactoryBot.create(:submission)
    submission.exercise.update_column(:name, 'removed-by-refresh')
    controller.current_user = submission.user

    get :index, params: { submission_id: submission.id }

    expect(response).to have_http_status(:not_found)
  end
end
