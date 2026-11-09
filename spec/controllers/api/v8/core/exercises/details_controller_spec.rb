# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::Exercises::DetailsController, type: :controller do
  let(:visible_exercise) { FactoryBot.create(:exercise) }
  let(:hidden_course_exercise) { FactoryBot.create(:exercise, course: FactoryBot.create(:course, hidden: true)) }

  before :each do
    allow(controller).to receive(:doorkeeper_token).and_return(nil)
  end

  it 'leaves out exercises of courses the caller cannot read' do
    get :show, params: { ids: "#{visible_exercise.id},#{hidden_course_exercise.id}" }
    expect(response).to have_http_status(200)
    expect(response.parsed_body['exercises'].pluck('id')).to eq([visible_exercise.id])
  end
end
