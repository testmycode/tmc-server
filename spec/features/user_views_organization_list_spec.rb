require 'spec_helper'

feature 'User views organization list', feature: true do
  include IntegrationTestActions

  before :each do
    @organization1 = FactoryGirl.create :accepted_organization, name: 'Organization One'
    @organization2 = FactoryGirl.create :accepted_organization, name: 'Organization Two'
    @organization3 = FactoryGirl.create :accepted_organization, name: 'Organization Three'
    @organization4 = FactoryGirl.create :accepted_organization, name: 'Organization Four'
    @organization5 = FactoryGirl.create :accepted_organization, name: 'Organization Five'

    @course1 = FactoryGirl.create :course, name: 'org1course1', organization: @organization1
    @course2 = FactoryGirl.create :course, name: 'org3course1', organization: @organization3
    @course3 = FactoryGirl.create :course, name: 'org4course1', organization: @organization4
    @course4 = FactoryGirl.create :course, name: 'org4course2', organization: @organization4

    @user = FactoryGirl.create :user, password: 'foobar'
    @teacher = FactoryGirl.create :user, password: 'foobar'
    @assistant = FactoryGirl.create :user, password: 'foobar'

    Teachership.create! user: @teacher, organization: @organization1
    Teachership.create! user: @teacher, organization: @organization2

    Assistantship.create! user: @assistant, course: @course1
    Assistantship.create! user: @assistant, course: @course2

    FactoryGirl.create :awarded_point, course: @course1, user: @user
    FactoryGirl.create :awarded_point, course: @course3, user: @user
    FactoryGirl.create :awarded_point, course: @course4, user: @user

    visit '/'
  end

  scenario 'Guest does not see the My organization list' do
    expect(page).to_not have_content('My organizations')
  end

  scenario 'Student can see the organizations in which they have awarded points' do
    log_in_as(@user.login, 'foobar')
    expect(page).to have_content('My organizations')

    within('table#my-organizations-table') do
      expect(page).to have_content('Organization Four')
      expect(page).to have_content('Organization One')
      expect(page).to_not have_content('Organization Two')
      expect(page).to_not have_content('Organization Three')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'Assistant can see the organizations in which they are an assistant in some course(s)' do
    log_in_as(@assistant.login, 'foobar')
    expect(page).to have_content('My organizations')

    within('table#my-organizations-table') do
      expect(page).to have_content('Organization One')
      expect(page).to have_content('Organization Three')
      expect(page).to_not have_content('Organization Two')
      expect(page).to_not have_content('Organization Four')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'Teacher can see the organizations they teach' do
    log_in_as(@teacher.login, 'foobar')
    expect(page).to have_content('My organizations')

    within('table#my-organizations-table') do
      expect(page).to have_content('Organization One')
      expect(page).to have_content('Organization Two')
      expect(page).to_not have_content('Organization Three')
      expect(page).to_not have_content('Organization Four')
      expect(page).to_not have_content('Organization Five')
    end
  end

  scenario 'User with multiple own organizations with different conditions sees them all' do
    user = FactoryGirl.create :user, password: 'foobar'
    Teachership.create! user: user, organization: @organization1
    Assistantship.create! user: user, course: @course2
    FactoryGirl.create :awarded_point, course: @course3, user: user

    log_in_as(user.login, 'foobar')
    expect(page).to have_content('My organization')

    within('table#my-organizations-table') do
      expect(page).to have_content('Organization One')
      expect(page).to have_content('Organization Three')
      expect(page).to have_content('Organization Four')
      expect(page).to_not have_content('Organization Two')
      expect(page).to_not have_content('Organization Five')
    end
  end
end
