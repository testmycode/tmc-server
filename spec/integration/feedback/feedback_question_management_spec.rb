require 'spec_helper'

describe "Feedback question management", :type => :request, :integration => true do
  include IntegrationTestActions

  before :each do
    @user = FactoryGirl.create(:admin, :password => 'xooxer')
    visit '/'
    log_in_as(@user.login, 'xooxer')

    create_new_course :name => 'TheCourse', :source_url => Dir.pwd + '/unused'

    visit '/'
    click_link 'TheCourse'
    click_link 'Manage feedback questions'
  end

  it "should permit creating questions" do
    click_link 'Add question'
    fill_in 'Question', :with => "How's it going?"
    choose 'Text area'
    click_button 'Create question'

    click_link 'Add question'
    fill_in 'Question', :with => "What's the weather like?"
    choose 'Text area'
    click_button 'Create question'

    expect(page).to have_content("How's it going?")
    expect(page).to have_content("What's the weather like?")
  end

  it "should permit changing the question text" do
    click_link 'Add question'
    fill_in 'Question', :with => "How's it going?"
    choose 'Text area'
    click_button 'Create question'

    click_link "How's it going?"
    fill_in 'Question', :with => "How are you doing?"
    click_button 'Save'

    expect(page).to have_content("How are you doing?")
  end
end
