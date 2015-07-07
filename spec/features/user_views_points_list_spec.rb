require 'spec_helper'

feature 'User views points list', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @course = FactoryGirl.create :course, name: 'course1', organization: @organization
    @user = FactoryGirl.create :user, password: 'passwd'

    @e1 = FactoryGirl.create :exercise, course: @course
    @e2 = FactoryGirl.create :exercise, course: @course
    @e3 = FactoryGirl.create :exercise, course: @course
    @avp1 = FactoryGirl.create :available_point, exercise: @e1
    @avp2 = FactoryGirl.create :available_point, exercise: @e2
    @avp3 = FactoryGirl.create :available_point, exercise: @e3

    [@avp1, @avp2, @avp3].each { |p| p.award_to(@user) }

    visit '/'
    log_in_as(@user.login, @user.password)
  end

  scenario 'User can see all points normally if no exercise was submitted late' do
    visit "/org/slug/courses/#{@course.id}/points"
    expect(page).to have_content('3/3')
    expect(page).to_not have_link('Show/hide late points')
  end

  scenario 'User can see a link to show late points is any exercise was submitted late' do
    AwardedPoint.last.update(late: true)

    visit "/org/slug/courses/#{@course.id}/points"
    expect(page).to have_link('Show/hide late points')

    click_link 'Show/hide late points'
    expect(page).to have_content('0+1/1')
    expect(page).to have_content('2+1/3')
  end

  scenario 'User can see the points for individual exercises normally' do
    visit "/org/slug/courses/#{@course.id}/points/#{@e1.gdocs_sheet}"
    expect(page).to have_content('✔')
    expect(page).to_not have_content('✔*')
  end

  scenario 'User can see the individual points that were submitted late' do
    AwardedPoint.update_all(late: true)

    visit "/org/slug/courses/#{@course.id}/points/#{@e1.gdocs_sheet}"
    expect(page).to have_content('✔*')
  end
end
