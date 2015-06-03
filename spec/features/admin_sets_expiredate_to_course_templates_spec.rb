require 'spec_helper'

feature 'Admin sets expiredate to course templates', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @user = FactoryGirl.create :user, password: 'foobar'
    @admin = FactoryGirl.create :admin, password: 'xooxer'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization

    @ct1 = FactoryGirl.create :course_template, title: 'template1'
    @ct2 = FactoryGirl.create :course_template, title: 'template2', expires_at: Time.now - 1.days

    visit '/'
  end

  scenario 'Admin succeeds at setting expiredate' do
    log_in_as(@admin.login, 'xooxer')
    visit('/course_templates')

    find('table').find('tr:nth-child(2)').click_link('Edit')

    fill_in 'course_template_expires_at', with: '2020-01-01'
    click_button 'Update Course template'

    expect(page).to have_content('2020-01-01')
  end

  scenario "Teacher doesn't see expired course templates" do
    log_in_as(@teacher.login, 'xooxer')
    visit('/org/slug/course_templates')

    expect(page).to have_content('template1')
    expect(page).not_to have_content('template2')
  end

  scenario "Teacher can't create course from expired template" do
    log_in_as(@teacher.login, 'xooxer')
    visit("/org/slug/course_templates/#{@ct2.id}")
    expect(page).to have_content('Access denied')
  end
end
