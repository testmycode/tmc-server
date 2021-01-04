# frozen_string_literal: true

require 'spec_helper'

feature 'User views organization list', feature: true do
  include IntegrationTestActions

  before :each do
    @organization1 = FactoryBot.create :accepted_organization, name: 'Organization One'
    @organization2 = FactoryBot.create :accepted_organization, name: 'Organization Two'
    @organization3 = FactoryBot.create :accepted_organization, name: 'Organization Three'
    @organization4 = FactoryBot.create :accepted_organization, name: 'Organization Four'
    @organization5 = FactoryBot.create :accepted_organization, name: 'Organization Five'

    @course1 = FactoryBot.create :course, name: 'org1course1', organization: @organization1
    @course2 = FactoryBot.create :course, name: 'org3course1', organization: @organization3
    @course3 = FactoryBot.create :course, name: 'org4course1', organization: @organization4
    @course4 = FactoryBot.create :course, name: 'org4course2', organization: @organization4

    @user = FactoryBot.create :verified_user, password: 'foobar'
    @teacher = FactoryBot.create :verified_user, password: 'foobar'
    @assistant = FactoryBot.create :verified_user, password: 'foobar'

    Teachership.create! user: @teacher, organization: @organization1
    Teachership.create! user: @teacher, organization: @organization2

    Assistantship.create! user: @assistant, course: @course1
    Assistantship.create! user: @assistant, course: @course2

    FactoryBot.create :awarded_point, course: @course1, user: @user
    FactoryBot.create :awarded_point, course: @course3, user: @user
    FactoryBot.create :awarded_point, course: @course4, user: @user

    visit '/'
  end

  scenario 'Guest does not see the My organization list' do
    expect(page).to_not have_content('My Organizations')
  end

  scenario 'Student can see the organizations in which they have awarded points' do
    log_in_as(@user.login, 'foobar')
    expect(page).to have_content('My Organizations')

    within('div#my-orgs-list') do
      expect(page).to have_content('Organization Four')
      expect(page).to have_content('Organization One')
      expect(page).to_not have_content('Organization Two')
      expect(page).to_not have_content('Organization Three')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'Assistant can see the organizations in which they are an assistant in some course(s)' do
    log_in_as(@assistant.login, 'foobar')
    expect(page).to have_content('My Organizations')

    within('div#my-orgs-list') do
      expect(page).to have_content('Organization One')
      expect(page).to have_content('Organization Three')
      expect(page).to_not have_content('Organization Two')
      expect(page).to_not have_content('Organization Four')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'Teacher can see the organizations they teach' do
    log_in_as(@teacher.login, 'foobar')
    expect(page).to have_content('My Organizations')

    within('div#my-orgs-list') do
      expect(page).to have_content('Organization One')
      expect(page).to have_content('Organization Two')
      expect(page).to_not have_content('Organization Three')
      expect(page).to_not have_content('Organization Four')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'User with multiple own organizations with different conditions sees them all' do
    user = FactoryBot.create :verified_user, password: 'foobar'
    Teachership.create! user: user, organization: @organization1
    Assistantship.create! user: user, course: @course2
    FactoryBot.create :awarded_point, course: @course3, user: user

    log_in_as(user.login, 'foobar')
    expect(page).to have_content('My Organization')

    within('div#my-orgs-list') do
      expect(page).to have_content('Organization One')
      expect(page).to have_content('Organization Three')
      expect(page).to have_content('Organization Four')
      expect(page).to_not have_content('Organization Two')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'Hidden organization is not visible to user in organization list' do
    @organization = FactoryBot.create :accepted_organization
    @organization.hidden = true
    @organization.save!
    log_in_as(@user.login, 'foobar')
    expect(page).to_not have_content(@organization.name)
  end
end
