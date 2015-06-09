require 'spec_helper'

feature 'Teacher has admin abilities to own course', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create(:accepted_organization, slug: 'slug')
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization
    @user = FactoryGirl.create :user, password: 'foobar'

    @course = Course.create!(name: 'mycourse', source_backend: 'git', source_url: 'https://github.com/testmycode/tmc-testcourse.git', organization: @organization)
    @course.refresh

    @submission = FactoryGirl.create :submission, course: @course, user: @user, exercise_name: 'trivial'
    @submission_data = FactoryGirl.create :submission_data, submission: @submission

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

  scenario 'Teacher can see all submissions for his organizations courses' do
    visit '/org/slug/courses/1'

    expect(page).to have_content('Latest submissions')
    expect(page).not_to have_content('No data available in table')
    expect(page).to have_content('Showing 1 to 1 of 1 entries')

    click_link('Details')

    expect(page).to have_content('Submission 1')
    expect(page).to have_content('Submitted at')
    expect(page).to have_content('Test Results')
    expect(page).not_to have_content('Access denied')
  end
end
