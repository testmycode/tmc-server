require 'spec_helper'

feature 'Teacher disables exercises', feature: true do
  include IntegrationTestActions

  before :each do
    @teacher = FactoryGirl.create :user
    @user = FactoryGirl.create :user
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    Teachership.create!(user: @teacher, organization: @organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    @ex1 = FactoryGirl.create(:exercise, course: @course)
    @ex2 = FactoryGirl.create(:exercise, course: @course)
    @ex3 = FactoryGirl.create(:exercise, course: @course)
    @ex4 = FactoryGirl.create(:exercise, course: @course)

    visit '/'
  end

  scenario 'Teacher disables exercises' do
    log_in_as(@teacher.login, @teacher.password)
    visit '/org/slug/courses/1'

    click_link 'Manage exercises'

    [@ex1, @ex2, @ex3].each do |ex|
      check "exercise_#{ex.name}"
    end

    click_button 'Disable selected'

    [@ex1, @ex2, @ex3].each do |ex|
      expect(page).to have_content("#{ex.name} (disabled)")
    end
    expect(page).to_not have_content("#{@ex4.name} (disabled)")
  end

  scenario 'Teacher enables exercises' do
    @ex1.disabled!
    @ex2.disabled!
    @ex3.disabled!
    @ex4.enabled!

    log_in_as(@teacher.login, @teacher.password)
    visit '/org/slug/courses/1'

    click_link 'Manage exercises'

    [@ex1, @ex2, @ex3, @ex4].each do |ex|
      check "exercise_#{ex.name}"
    end

    click_button 'Enable selected'

    [@ex1, @ex2, @ex3, @ex4].each do |ex|
      expect(page).to have_content("#{ex.name}")
      expect(page).to_not have_content("#{ex.name} (disabled)")
    end
  end
end
