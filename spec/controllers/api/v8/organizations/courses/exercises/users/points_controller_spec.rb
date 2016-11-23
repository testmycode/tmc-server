require 'spec_helper'

describe Api::V8::Organizations::Courses::Exercises::Users::PointsController, type: :controller do
  let(:slug) { 'organ' }
  let!(:organization) { FactoryGirl.create(:accepted_organization, slug: slug) }
  let(:course_name) { 'testcourse' }
  let(:course_name_with_slug) { "#{slug}-#{course_name}" }
  let!(:course) { FactoryGirl.create(:course, name: course_name_with_slug, organization: organization) }
  let(:exercise_name) { 'testexercise' }
  let!(:exercise) { FactoryGirl.create(:exercise, name: exercise_name, course: course) }
  let(:hidden_exercise_name) { 'hiddentestexercise' }
  let!(:hidden_exercise) { FactoryGirl.create(:exercise, name: hidden_exercise_name, course: course, hidden: true) }
  let!(:available_point) { FactoryGirl.create(:available_point, exercise: exercise) }
  let(:admin) { FactoryGirl.create(:admin, password: 'xooxer') }
  let(:user) { FactoryGirl.create(:user, login: 'user', password: 'xooxer') }
  let(:guest) { Guest.new }
  let(:submission1) { FactoryGirl.create(:submission, course: course, user: admin, exercise: exercise) }
  let(:available_point1_name) { 'adminpoint' }
  let(:available_point1) { FactoryGirl.create(:available_point, name: available_point1_name, exercise: exercise) }
  let!(:awarded_point1) { FactoryGirl.create(:awarded_point, course: course, name: available_point.name, submission: submission1, user: admin) }
  let(:submission2) { FactoryGirl.create(:submission, course: course, user: user, exercise: exercise) }
  let(:available_point2_name) { 'userpoint' }
  let(:available_point2) { FactoryGirl.create(:available_point, name: available_point2_name, exercise: exercise) }
  let!(:awarded_point2) { FactoryGirl.create(:awarded_point, course: course, name: available_point2.name, submission: submission1, user: user) }
  let!(:exercise_no_points) { FactoryGirl.create(:exercise, name: 'nopoints', course: course) }

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'As a guest' do
    let(:token) { nil }
    describe 'when searching for awarded points' do
      it 'should show authentication error' do
        get :index, course_name: course_name, organization_slug: slug, user_id: 'current', exercise_name: exercise.name
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to have_content('Authentication required')
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when searching for users awarded points by user id' do
      describe 'and using course id' do
        it 'should return only correct users awarded points' do
          get :index, course_name: course_name, organization_slug: slug, user_id: 'current', exercise_name: exercise.name
          expect(response.body).to have_content awarded_point1.name
          expect(response.body).not_to have_content awarded_point2.name
        end
      end
    end
  end
end
