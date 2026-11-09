# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe CourseTemplateRefreshChannel, type: :channel do
  let(:course_template) { FactoryBot.create(:course_template) }
  let(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:course) { FactoryBot.create(:course, organization: organization, course_template: course_template, source_url: course_template.source_url) }

  it 'streams refresh progress to a teacher of a course using the template' do
    teacher = FactoryBot.create(:user)
    Teachership.create!(user: teacher, organization: organization)
    stub_connection current_user: teacher
    subscribe courseTemplateId: course_template.id
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("CourseTemplateRefreshChannel-#{course_template.id}")
  end

  it 'streams refresh progress to an admin' do
    stub_connection current_user: FactoryBot.create(:admin)
    subscribe courseTemplateId: course_template.id
    expect(subscription).to be_confirmed
  end

  it 'rejects a student' do
    stub_connection current_user: FactoryBot.create(:user)
    subscribe courseTemplateId: course_template.id
    expect(subscription).to be_rejected
  end
end
