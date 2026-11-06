# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Organizations::Courses::StudyrightEligibilityController, type: :controller do
  let(:organization) { FactoryBot.create(:organization, slug: 'mooc') }
  let(:course) { FactoryBot.create(:course, organization: organization, name: 'mooc-2019-ohjelmointi') }
  let(:admin) { FactoryBot.create(:admin) }
  let(:token) { double resource_owner_id: admin.id, acceptable?: true }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  def apply_for_study_right(user)
    UserAppDatum.create!(user: user, namespace: 'ohjelmoinnin-mooc-2019', field_name: 'applies_for_study_right', value: 't')
  end

  it 'handles courses with few groups, some without points' do
    graded = %w[osa01-e1 osa02-e1].map { |name| FactoryBot.create(:exercise, course: course, name: name) }
    FactoryBot.create(:exercise, course: course, name: 'osa03-e1')
    points = graded.map { |exercise| FactoryBot.create(:available_point, exercise: exercise) }

    eligible = FactoryBot.create(:user)
    partial = FactoryBot.create(:user)
    [eligible, partial].each { |user| apply_for_study_right(user) }
    points.each { |point| FactoryBot.create(:awarded_point, course: course, user: eligible, name: point.name) }
    FactoryBot.create(:awarded_point, course: course, user: partial, name: points.first.name)

    get :eligible_students, params: { organization_slug: 'mooc', course_name: '2019-ohjelmointi' }

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)['eligible_students'].map { |s| s['id'] }).to eq([eligible.id])
  end
end
