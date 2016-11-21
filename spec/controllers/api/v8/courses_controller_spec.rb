require 'spec_helper'

describe Api::V8::CoursesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:course_name) { 'testcourse' }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}") }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  let!(:current_user_course_point) { FactoryGirl.create(:awarded_point, course: course, user: current_user) unless current_user.guest? }
  let!(:current_user_point) { FactoryGirl.create(:awarded_point, user: current_user) unless current_user.guest? }
  let!(:course_point) { FactoryGirl.create(:awarded_point, course: course) }
  let!(:point) { FactoryGirl.create(:awarded_point) }

  before(:each) do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'GET get_course by id' do

    describe 'as admin' do
      let(:current_user) { admin }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it 'shows course information' do
          get :get_course, course_id: course.id
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's ID given" do
        it 'shows course information' do
          course.hidden = true
          course.save!
          get :get_course, course_id: course.id
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_course, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'as user' do
      let(:current_user) { user }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it 'shows course information' do
          get :get_course, course_id: course.id
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's ID given" do
        it 'shows authorization error' do
          course.hidden = true
          course.save!
          get :get_course, course_id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to include 'You are not authorized'
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_course, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when course ID given' do
        it 'shows authentication error' do
          get :get_course, course_id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe "when hidden course's ID given" do
        it 'shows authentication error' do
          course.hidden = true
          course.save!
          get :get_course, course_id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when invalid course ID given' do
        it 'shows authentication error' do
          get :get_course, course_id: -1
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
    end

  end

  describe 'GET get_course by name' do

    describe 'when logged as admin' do
      let(:current_user) { admin }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when organization id and course name given' do
        it 'shows course information' do
          get :get_course, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's organization id and course name given" do
        it 'shows course information' do
          course.hidden = true
          course.save!
          get :get_course, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe 'when invalid organization id and valid course name given' do
        it 'error about finding course' do
          get :get_course, {slug: 'bad', course_name: course_name}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when valid organization id and invalid course name given' do
        it 'error about finding course' do
          get :get_course, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when invalid organization id and invalid course name given' do
        it 'error about finding course' do
          get :get_course, {slug: 'bad', course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'when logged as user' do
      let(:current_user) { user }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when organization id and course name given' do
        it 'shows course information' do
          get :get_course, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course.name
        end
      end
      describe "when hidden course's organization id and course name given" do
        it 'shows authorization error' do
          course.hidden = true
          course.save!
          get :get_course, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to include 'You are not authorized'
        end
      end
      describe 'when invalid organization id and valid course name given' do
        it 'shows error about finding course' do
          get :get_course, {slug: 'bad', course_name: course_name}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when valid organization id and invalid course name given' do
        it 'error about finding course' do
          get :get_course, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
      describe 'when invalid organization id and invalid course name given' do
        it 'error about finding course' do
          get :get_course, {slug: 'bad', course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when organization id and course name given' do
        it 'shows authentication error' do
          get :get_course, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe "when hidden course's organization id and course name given" do
        it 'shows authentication error' do
          course.hidden = true
          course.save!
          get :get_course, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when invalid organization id and valid course name given' do
        it 'shows authentication error' do
          get :get_course, {slug: 'bad', course_name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when valid organization id and invalid course name given' do
        it 'shows authentication error' do
          get :get_course, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
      describe 'when invalid organization id and invalid course name given' do
        it 'shows authentication error' do
          get :get_course, {slug: 'bad', course_name: 'bad'}
          expect(response).to have_http_status(403)
          expect(response.body).to include 'Authentication required'
        end
      end
    end
  end

  describe 'GET current_users_points' do

    describe 'as admin' do
      let(:current_user) { FactoryGirl.create(:admin) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
    end

    describe 'as user' do
      let(:current_user) { FactoryGirl.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(response.body).to eq '[]'
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, course_id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to eq '[]'
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
    end
  end

  describe 'GET users_points' do
    describe 'as admin' do
      let(:current_user) { FactoryGirl.create(:admin) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: point.course_id, user_id: point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, {course_id: -1, user_id: point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name, user_id: course_point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course_point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad', user_id: course_point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as user' do
      let(:current_user) { FactoryGirl.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: point.course_id, user_id: point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, {course_id: -1, user_id: point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name, user_id: course_point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course_point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad', user_id: course_point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as another user' do
      let(:current_user) { user2 }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: point.course_id, user_id: point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, {course_id: -1, user_id: point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name, user_id: course_point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad', user_id: course_point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_user, {course_id: point.course_id, user_id: point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_user, {course_id: -1, user_id: point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_user, {slug: organization.slug, course_name: course_name, user_id: course_point.user_id}
          expect(response).to have_http_status(:success)
          expect(response.body).to include course_point.name
          expect(response.body).not_to include point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_user, {slug: organization.slug, course_name: 'bad', user_id: course_point.user_id}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end
  end

  describe 'GET points' do
    describe 'as admin' do
      let(:current_user) { FactoryGirl.create(:admin) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_all, {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_all, {course_id: -1}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_all, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_all, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as user' do
      let(:current_user) { FactoryGirl.create(:user) }
      let(:token) { double resource_owner_id: current_user.id, acceptable?: true }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_all, {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_all, {course_id: -1}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_all, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_all, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include current_user_course_point.name
          expect(response.body).not_to include current_user_point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end

    describe 'as guest' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      describe 'when course ID given' do
        it "shows only user's point information" do
          get :get_points_all, {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course ID given' do
        it 'shows error about finding course' do
          get :get_points_all, {course_id: -1}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
      describe 'when course name given' do
        it "shows only user's point information" do
          get :get_points_all, {slug: organization.slug, course_name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include point.name
          expect(response.body).to include course_point.name
        end
      end
      describe 'when invalid course name given' do
        it 'shows error about finding course' do
          get :get_points_all, {slug: organization.slug, course_name: 'bad'}
          expect(response).to have_http_status(:missing)
          expect(response.body).to include "Couldn't find Course"
          expect(response.body).not_to include point.name
          expect(response.body).not_to include course_point.name
        end
      end
    end
  end
end
