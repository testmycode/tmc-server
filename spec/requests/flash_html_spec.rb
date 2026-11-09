# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'HTML flash messages', type: :request do
  it 'survive the redirect through the session' do
    FactoryBot.create(:admin, login: 'admin', password: 'secret')
    exercise = FactoryBot.create(:exercise)
    allow_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).and_return(true)
    post '/sessions', params: { session: { login: 'admin', password: 'secret' } }

    post "/org/#{exercise.course.organization.slug}/exercises/#{exercise.id}/toggle_submission_result_visibility"
    follow_redirect!

    expect(response.body).to include('<h4>Exercise status update:</h4>')
    expect(response.body).to include('Points are now <b>hidden</b>')
  end
end
