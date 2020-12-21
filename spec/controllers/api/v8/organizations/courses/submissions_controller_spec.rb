# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Organizations::Courses::SubmissionsController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:teacher) { FactoryGirl.create(:user) }
  let!(:assistant) { FactoryGirl.create(:user) }
  let!(:admin) { FactoryGirl.create(:admin) }
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let(:course_name) { 'testcourse' }
  let(:course_name_with_slug) { "#{organization.slug}-#{course_name}" }
  let!(:course) { FactoryGirl.create(:course, name: course_name_with_slug.to_s, organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) do
    FactoryGirl.create(:submission,
                       course: course,
                       user: user,
                       exercise: exercise)
  end

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
    Teachership.create(user: teacher, organization: organization)
    Assistantship.create(user: assistant, course: course)
  end

  describe 'GET all submissions' do
    describe 'by course name as json' do
      describe 'as an admin' do
        describe 'when logged in' do
          before :each do
            controller.current_user = admin
          end

          it 'should show all of the submissions' do
            two_subs_by_name
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: admin.id, acceptable?: true }

          it 'should show all of the submissions' do
            two_subs_by_name
          end
        end
      end

      describe 'as a teacher' do
        describe 'when logged in' do
          before :each do
            controller.current_user = teacher
          end

          it 'should show all of the submissions in my organizations' do
            two_subs_by_name
          end

          it 'should not show any submissions outside my organizations' do
            no_other_orgs_subs_for_teacher(organization_slug: organization.slug, course_name: course_name)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: teacher.id, acceptable?: true }

          it 'should show all of the submissions in my organizations' do
            two_subs_by_name
          end

          it 'should not show any submissions outside my organizations' do
            no_other_orgs_subs_for_teacher(organization_slug: organization.slug, course_name: course_name)
          end
        end
      end

      describe 'as an assistant' do
        describe 'when logged in' do
          before :each do
            controller.current_user = assistant
          end

          it 'should show all of the submissions in my courses' do
            two_subs_by_name
          end

          it 'should not show any submissions outside my courses' do
            no_other_courses_subs_for_assistant(organization_slug: organization.slug, course_name: course_name)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: assistant.id, acceptable?: true }

          it 'should show all of the submissions in my courses' do
            two_subs_by_name
          end

          it 'should not show any submissions outside my courses' do
            no_other_courses_subs_for_assistant(organization_slug: organization.slug, course_name: course_name)
          end
        end
      end

      describe 'as a student' do
        describe 'when logged in' do
          before :each do
            controller.current_user = user
          end

          it 'should show my own submissions' do
            all_own_subs(organization_slug: organization.slug, course_name: course_name)
          end

          it "should not show other users' submissions" do
            no_other_users_subs_for_student(organization_slug: organization.slug, course_name: course_name)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it 'should show my own submissions' do
            all_own_subs(organization_slug: organization.slug, course_name: course_name)
          end

          it "should not show other users' submissions" do
            no_other_users_subs_for_student(organization_slug: organization.slug, course_name: course_name)
          end
        end
      end

      describe 'as an unauthorized user' do
        before :each do
          controller.current_user = Guest.new
        end

        it 'should not show any submissions' do
          get :index, params: { organization_slug: organization.slug, course_name: course_name }

          expect(response).to have_http_status(401)
          expect(response.body).to have_content('Authentication required')
        end
      end
    end
  end

  private

    def two_subs_by_name
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      sub1 = FactoryGirl.create(:submission, user: user1, course: course)
      sub2 = FactoryGirl.create(:submission, user: user2, course: course)

      get :index, params: { organization_slug: organization.slug, course_name: course_name }

      r = JSON.parse response.body

      expect(r.any? { |e|  e['id'] == sub1.id && e['user_id'] == user1.id }).to be(true), 'incorrect submission or user id'
      expect(r.any? { |e|  e['id'] == sub2.id && e['user_id'] == user2.id }).to be(true), 'incorrect submission or user id'
    end

    def all_own_subs(parameters)
      get :index, params: parameters

      r = JSON.parse response.body

      expect(r.any? { |e|  e['id'] == submission.id && e['user_id'] == user.id }).to be(true), 'incorrect submission or user id'
    end

    def no_other_orgs_subs_for_teacher(parameters)
      other_organization = FactoryGirl.create(:accepted_organization)
      other_course = FactoryGirl.create(:course, organization: other_organization)
      other_exercise = FactoryGirl.create(:exercise, course: other_course)
      other_user = FactoryGirl.create(:user)
      other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

      get :index, params: parameters

      r = JSON.parse response.body

      expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
    end

    def no_other_courses_subs_for_assistant(parameters)
      other_course = FactoryGirl.create(:course, organization: organization)
      other_exercise = FactoryGirl.create(:exercise, course: other_course)
      other_user = FactoryGirl.create(:user)
      other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

      get :index, params: parameters

      r = JSON.parse response.body

      expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
    end

    def no_other_users_subs_for_student(parameters)
      other_user = FactoryGirl.create(:user)
      other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

      get :index, params: parameters

      r = JSON.parse response.body

      expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
    end
end
