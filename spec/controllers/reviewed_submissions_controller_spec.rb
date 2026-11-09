# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe ReviewedSubmissionsController, type: :controller do
  render_views

  it 'lists reviews whose reviewer has been deleted' do
    course = FactoryBot.create(:course)
    submission = FactoryBot.create(:submission, course: course, reviewed: true)
    FactoryBot.create(:review, submission: submission).update_column(:reviewer_id, nil)
    controller.current_user = FactoryBot.create(:admin)

    get :index, params: { organization_id: course.organization.slug, course_id: course.id }

    expect(response).to be_successful
  end
end
