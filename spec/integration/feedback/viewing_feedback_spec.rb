# frozen_string_literal: true

require 'spec_helper'

describe 'Viewing feedback', type: :request, integration: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryBot.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryBot.create(:user)
    Teachership.create user_id: @teacher.id, organization_id: @organization.id
    @user = FactoryBot.create(:admin, password: 'xooxer')
    visit '/'
    log_in_as(@user.login, 'xooxer')

    @course = FactoryBot.create(:course, organization: @organization)
    @question = FactoryBot.create(:feedback_question, course: @course)

    visit '/org/slug/courses'
  end

  it 'should be possible per-course' do
    @exercise = FactoryBot.create(:exercise, course: @course)
    @answer = FactoryBot.create(:feedback_answer, feedback_question: @question, course: @course, exercise: @exercise, answer: 'this is the answer')

    click_link @course.title
    click_link 'View feedback'
    expect(page).to have_content('this is the answer')
  end

  it 'should be possible per-exercise' do
    @ex1 = FactoryBot.create(:exercise, course: @course)
    @ex2 = FactoryBot.create(:exercise, course: @course)
    @answer = FactoryBot.create(:feedback_answer, course: @course, exercise: @ex1, answer: 'this is the answer')

    click_link @course.title
    click_link @ex1.name
    click_link 'View feedback'
    expect(page).to have_content('this is the answer')

    visit '/org/slug/courses'
    click_link @course.title
    click_link @ex2.name
    click_link 'View feedback'
    expect(page).not_to have_content('this is the answer')
  end
end
