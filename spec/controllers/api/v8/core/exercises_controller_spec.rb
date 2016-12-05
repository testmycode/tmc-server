require 'spec_helper'

describe Api::V8::Core::ExercisesController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:admin) { FactoryGirl.create(:admin) }
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-testcourse", organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) do
    FactoryGirl.create(:submission,
                       course: course,
                       user: user,
                       exercise: exercise)
  end

  before :each do
    controller.stub(:doorkeeper_token) { token }
    Teachership.create(user: teacher, organization: organization)
    Assistantship.create(user: assistant, course: course)
  end
end