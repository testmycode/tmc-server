require 'spec_helper'

feature 'Teacher can edit course parameters', feature: true do
  include IntegrationTestActions

  before :each do
    @teacher = FactoryGirl.create :user, password: 'foobar'
    @new_teacher = FactoryGirl.create :user, password: 'newfoobar'
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    Teachership.create!(user: @teacher, organization: @organization)
    visit '/org/slug'
  end

  scenario 'Teacher succeeds at editing title, description and material url'

  scenario 'Teacher cannot edit courses that they dont teach'
end