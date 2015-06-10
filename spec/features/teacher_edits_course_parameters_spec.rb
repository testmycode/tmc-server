require 'spec_helper'

feature 'Teacher can edit course parameters', feature: true do
  include IntegrationTestActions

  before :each do
    @user = FactoryGirl.create :user, password: 'xooxer'
    @teacher = FactoryGirl.create :user, password: 'foobar'
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @course = FactoryGirl.create :course, title: 'oldTitle', description: 'oldDescription', material_url: 'oldMaterial.com', organization: @organization
    FactoryGirl.create :course, title: 'dontchange', organization: @organization
    Teachership.create!(user: @teacher, organization: @organization)
    visit '/org/slug'
  end

  scenario 'Teacher succeeds at editing title, description and material url' do
    log_in_as @teacher.login, 'foobar'
    click_link 'oldTitle'
    click_link 'Edit course parameters'

    fill_in 'course_title', with: 'newTitle'
    fill_in 'course_description', with: 'newDescription'
    fill_in 'course_material_url', with: 'newMaterial.com'
    click_button 'Update Course'

    expect(page).to have_content 'newTitle'
    expect(page).to have_content 'newDescription'
    expect(page).to have_link 'Material', href: 'http://newMaterial.com'

    visit '/org/slug'
    expect(page).to have_content 'newTitle'
    expect(page).to have_content 'dontchange'
  end

  scenario 'Teacher cannot edit if parameters are invalid' do
    log_in_as @teacher.login, 'foobar'
    click_link 'oldTitle'
    click_link 'Edit course parameters'

    fill_in 'course_title', with: 'a' * 41
    fill_in 'course_material_url', with: 'colons : galore'
    click_button 'Update Course'

    expect(page).to have_content 'Title is too long'
    expect(page).to have_content 'Material url should not contain colon'

    visit '/org/slug'
    expect(page).to have_content 'oldTitle'
    expect(page).to have_content 'dontchange'

    click_link 'oldTitle'
    expect(page).to have_content 'oldTitle'
    expect(page).to have_content 'oldDescription'
    expect(page).to have_link 'Material', href: 'http://oldMaterial.com'
  end

  scenario 'Teacher cannot edit courses that they dont teach' do
    log_in_as @user.login, 'xooxer'
    click_link 'oldTitle'
    expect(page).not_to have_button 'Update Course'
  end
end