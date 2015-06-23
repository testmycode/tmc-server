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
    visit_course @course

    click_link 'Manage exercises'

    [@ex1, @ex2, @ex3].each do |ex|
      check "course_exercises_#{ex.id}"
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
    visit_course @course

    click_link 'Manage exercises'

    [@ex1, @ex2, @ex3, @ex4].each do |ex|
      check "course_exercises_#{ex.id}"
    end

    click_button 'Enable selected'

    [@ex1, @ex2, @ex3, @ex4].each do |ex|
      expect(page).to have_content("#{ex.name}")
      expect(page).to_not have_content("#{ex.name} (disabled)")
    end
  end

  scenario 'Teacher can submit solutions for disabled exercises' do
    @ex1.disabled!
    @ex1.returnable_forced = true # Not an actual exercise, must force
    @ex1.save!

    log_in_as(@teacher.login, @teacher.password)
    visit_course @course

    click_link @ex1.name

    expect(page).to have_content('Submit answer')
  end

  scenario 'Student cannot see disabled exercises' do
    @ex3.disabled!
    @ex4.disabled!

    log_in_as(@user.login, @user.password)
    visit_course @course

    expect(page).to have_content("#{@ex1.name}")
    expect(page).to have_content("#{@ex2.name}")
    expect(page).to_not have_content("#{@ex3.name}")
    expect(page).to_not have_content("#{@ex4.name}")
  end

  scenario 'Student cannot access disabled exercise page' do
    @ex1.disabled!

    log_in_as(@user.login, @user.password)

    visit "/exercises/#{@ex1.id}"

    expect(page).to have_content('Access denied')
  end

  def visit_course(course)
    visit "/org/slug/courses/#{course.id}"
  end
end
