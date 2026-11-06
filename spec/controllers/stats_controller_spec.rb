# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe StatsController, type: :controller do
  describe 'GET submission stats as JSON' do
    before :each do
      @course = FactoryBot.create(:course)
      FactoryBot.create(:submission, course: @course)
    end

    def get_submissions(time_params)
      get :show, params: { organization_id: @course.organization.slug, course_id: @course.id, id: 'submissions', format: :json }.merge(time_params)
    end

    it 'responds 400 to an unparseable start_time' do
      get_submissions(start_time: 'not a time')
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to eq('Invalid start_time')
    end

    it 'responds 400 to an out-of-range end_time' do
      get_submissions(end_time: '2020-13-45')
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to eq('Invalid end_time')
    end

    it 'counts submissions in a valid range' do
      get_submissions(start_time: 1.day.ago.to_date.to_s, end_time: 1.day.from_now.to_date.to_s)
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to be_an(Array)
    end
  end
end
