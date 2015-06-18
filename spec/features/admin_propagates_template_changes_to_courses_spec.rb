require 'spec_helper'

feature 'Admin propagates template changes to all courses cloned from template', feature: true do
  include IntegrationTestActions

  before :each do
    @admin = FactoryGirl.create :admin, password: 'xooxer'
    @user = FactoryGirl.create :user, password: 'foobar'


    visit '/'
  end

  scenario 'Admin refreshes template, courses get updated'

end
