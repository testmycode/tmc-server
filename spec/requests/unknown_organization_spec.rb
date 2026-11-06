# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'Pages under an unknown organization slug', type: :request do
  let(:admin) { FactoryBot.create(:admin) }
  let(:course) { FactoryBot.create(:course) }
  let(:auth) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(admin.login, admin.password) } }

  [
    '/org/no-such-org/teachers',
    '/org/no-such-org/course_templates',
    '/org/no-such-org/stats',
    '/org/no-such-org/participants',
    '/org/no-such-org/courses/%<course>s/points',
    '/org/no-such-org/courses/%<course>s/unlock',
    '/org/no-such-org/courses/%<course>s/reviews',
    '/org/no-such-org/courses/%<course>s/feedback_questions',
    '/org/no-such-org/courses/%<course>s/course_notifications/new',
    '/setup/no-such-org/edit',
    '/setup/no-such-org/course_chooser'
  ].each do |path_template|
    it "responds 404 to #{path_template}" do
      get format(path_template, course: course.id), headers: auth
      expect(response).to have_http_status(:not_found)
    end
  end
end
