require 'spec_helper'

describe "Viewing feedback", :integration => true do
  include IntegrationTestActions

  before :each do
    @user = Factory.create(:admin, :password => 'xooxer')
    visit '/'
    log_in_as(@user.login, 'xooxer')

    @course = Factory.create(:course)
    @question = Factory.create(:feedback_question, :course => @course)

    visit '/'
  end

  it "should be possible per-course" do
    @exercise = Factory.create(:exercise, :course => @course)
    @answer = Factory.create(:feedback_answer, :feedback_question => @question, :course => @course, :exercise => @exercise, :answer => 'this is the answer')

    click_link @course.name
    click_link 'View feedback'
    page.should have_content('this is the answer')
  end

  it "should be possible per-exercise" do
    @ex1 = Factory.create(:exercise, :course => @course)
    @ex2 = Factory.create(:exercise, :course => @course)
    @answer = Factory.create(:feedback_answer, :course => @course, :exercise => @ex1, :answer => 'this is the answer')

    click_link @course.name
    click_link @ex1.name
    click_link 'View feedback'
    page.should have_content('this is the answer')

    visit '/'
    click_link @course.name
    click_link @ex2.name
    click_link 'View feedback'
    page.should_not have_content('this is the answer')
  end
end
