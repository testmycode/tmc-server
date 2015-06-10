require 'spec_helper'

feature 'Admin sets expiredate to course templates', feature: true do
  include IntegrationTestActions

  before :each do
    @organization = FactoryGirl.create :accepted_organization, slug: 'slug'
    @user = FactoryGirl.create :user, password: 'foobar'
    @admin = FactoryGirl.create :admin, password: 'xooxer'
    @teacher = FactoryGirl.create :user, password: 'xooxer'
    Teachership.create! user: @teacher, organization: @organization

    @ct = FactoryGirl.create :course_template, title: 'template1'
    @ct_expired_visible = FactoryGirl.create :course_template, title: 'template2', expires_at: Time.now - 1.days
    @ct_non_expired_visible = FactoryGirl.create :course_template, title: 'template3', expires_at: Time.now + 1.days, hidden: false
    @ct_expired_hidden = FactoryGirl.create :course_template, title: 'template4', expires_at: Time.now - 1.days, hidden: true
    @ct_non_expired_hidden = FactoryGirl.create :course_template, title: 'template5', expires_at: Time.now + 1.days, hidden: true

    visit '/'
  end

  scenario 'Admin succeeds at setting expiredate' do
    log_in_as(@admin.login, 'xooxer')
    visit('/course_templates')

    find('tr', text: 'template2').click_link('Edit')

    fill_in 'course_template_expires_at', with: '2020-01-01'
    click_button 'Update Course template'

    expect(page).to have_content('2020-01-01')
  end

  scenario 'Admin succeeds at toggling between hidden and non-hidden' do
    log_in_as(@admin.login, 'xooxer')
    visit('/course_templates')

    find('tr', text: 'template2').click_link('hide')
    expect(find('tr', text: 'template2')).to have_content('unhide')
    find('tr', text: 'template2').click_link('unhide')
    expect(find('tr', text: 'template2')).to have_content('hide')
  end

  scenario "Teacher doesn't see expired or hidden course templates" do
    log_in_as(@teacher.login, 'xooxer')
    visit('/org/slug/course_templates')

    expect(page).to have_content('template1')
    expect(page).not_to have_content('template2')
    expect(page).to have_content('template3')
    expect(page).not_to have_content('template4')
    expect(page).not_to have_content('template5')
  end

  scenario "Teacher can't create course from expired template" do
    log_in_as(@teacher.login, 'xooxer')
    visit("/org/slug/course_templates/#{@ct_expired_visible.id}")
    expect(page).to have_content('Access denied')
  end

  scenario "Teacher can't create course from hidden template" do
    log_in_as(@teacher.login, 'xooxer')
    visit("/org/slug/course_templates/#{@ct_non_expired_hidden.id}")
    expect(page).to have_content('Access denied')
  end
end
