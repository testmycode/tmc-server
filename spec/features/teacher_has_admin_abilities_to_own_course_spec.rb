require 'spec_helper'

feature 'Teacher has admin abilities to own course', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization

    @course = Course.create!(name: 'mycourse', source_backend: 'git', source_url: 'https://github.com/testmycode/tmc-testcourse.git', organization: @organization)
    @course.refresh

    visit '/'
    log_in_as(@teacher.login, 'xooxer')
  end

  scenario 'Teacher can see model solution for exercise' do
    visit '/exercises/1'
    expect(page).to have_content('View suggested solution')

    click_link 'View suggested solution'

    expect(page).to have_content('Solution for arith_funcs')
    expect(page).to have_content('src/Arith.java')
  end
end
