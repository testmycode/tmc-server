# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Courses::AllCoursesWithThisTemplateController, type: :controller do
  let(:template) { FactoryBot.create(:course_template) }
  let!(:course) { FactoryBot.create(:course, course_template: template, source_url: template.source_url) }
  let!(:hidden_course) { FactoryBot.create(:course, course_template: template, source_url: template.source_url, hidden: true) }
  let(:user) { FactoryBot.create(:user) }

  before :each do
    allow(controller).to receive(:doorkeeper_token).and_return(Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public'))
  end

  it 'lists only the courses the caller can read' do
    get :index, params: { course_id: course.id }
    expect(response).to have_http_status(200)
    expect(response.parsed_body.pluck('id')).to eq([course.id])
  end
end
