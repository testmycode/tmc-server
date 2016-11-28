require 'spec_helper'

describe Api::V8::Organizations::Courses::Users::SubmissionsController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:teacher) { FactoryGirl.create(:user) }
  let!(:assistant) { FactoryGirl.create(:user) }
  let!(:admin) { FactoryGirl.create(:admin) }
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let(:course_name) { 'testcourse' }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}", organization: organization) }
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

  describe "GET single user's submissions" do
    describe 'by course name as json' do
      describe 'as an admin' do
        describe 'when logged in' do
          before :each do
            controller.current_user = admin
          end

          it "should show given user's submissions" do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: admin.id, acceptable?: true }

          it "should show given user's submissions" do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end
      end

      describe 'as a teacher' do
        describe 'when logged in' do
          before :each do
            controller.current_user = teacher
          end

          it "should show given user's submissions in my organizations" do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end

          it 'should not show any submissions outside my organizations' do
            no_other_orgs_user_subs_for_teacher(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: teacher.id, acceptable?: true }

          it "should show given user's submissions in my organizations" do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end

          it 'should not show any submissions outside my organizations' do
            no_other_orgs_user_subs_for_teacher(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end
      end

      describe 'as an assistant' do
        describe 'when logged in' do
          before :each do
            controller.current_user = assistant
          end

          it "should show given user's submissions in my courses" do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end

          it 'should not show any submissions outside my courses' do
            no_other_courses_user_subs_for_assistant(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: assistant.id, acceptable?: true }

          it "should show given user's submissions in my courses" do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end

          it 'should not show any submissions outside my courses' do
            no_other_courses_user_subs_for_assistant(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end
      end

      describe 'as a student' do
        describe 'when logged in' do
          before :each do
            controller.current_user = user
          end

          it 'should show my own submissions' do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end

          it "should not show other users' submissions" do
            no_other_users_user_subs_for_student(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it 'should show my own submissions' do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end

          it "should not show other users' submissions" do
            no_other_users_user_subs_for_student(organization_slug: organization.slug, course_name: course_name, user_id: user.id)
          end
        end
      end

      describe 'as an unauthorized user' do
        before :each do
          controller.current_user = Guest.new
        end

        it 'should not show any submissions' do
          get :index, organization_slug: organization.slug, course_name: course_name, user_id: user.id

          expect(response).to have_http_status(403)
          expect(response.body).to have_content('Authentication required')
        end
      end
    end
  end

  describe "GET user's own submissions" do
    describe 'by course name as json' do
      describe 'as an user' do
        describe 'when logged in' do
          before :each do
            controller.current_user = user
          end

          it 'should show my own submissions' do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: 'current')
          end

          it "should not show other users' submissions" do
            no_other_users_own_subs_for_anyone(organization_slug: organization.slug, course_name: course_name, user_id: 'current')
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it 'should show my own submissions' do
            users_own_subs(organization_slug: organization.slug, course_name: course_name, user_id: 'current')
          end

          it "should not show other users' submissions" do
            no_other_users_own_subs_for_anyone(organization_slug: organization.slug, course_name: course_name, user_id: 'current')
          end
        end
      end

      describe 'as an unauthorized user' do
        before :each do
          controller.current_user = Guest.new
        end

        it 'should not show any submissions' do
          get :index, organization_slug: organization.slug, course_name: course_name, user_id: 'current'

          expect(response).to have_http_status(403)
          expect(response.body).to have_content('Authentication required')
        end
      end
    end
  end

  private

  def users_own_subs(parameters)
    get :index, parameters

    r = JSON.parse response.body

    expect(r.any? { |e|  e['id'] == submission.id && e['user_id'] == user.id }).to be(true), 'incorrect submission or user id'
  end

  def no_other_orgs_user_subs_for_teacher(parameters)
    other_organization = FactoryGirl.create(:accepted_organization)
    other_course = FactoryGirl.create(:course, organization: other_organization)
    other_exercise = FactoryGirl.create(:exercise, course: other_course)
    other_user = FactoryGirl.create(:user)
    other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

    get :index, parameters

    r = JSON.parse response.body

    expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
  end

  def no_other_courses_user_subs_for_assistant(parameters)
    other_course = FactoryGirl.create(:course, organization: organization)
    other_exercise = FactoryGirl.create(:exercise, course: other_course)
    other_user = FactoryGirl.create(:user)
    other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

    get :index, parameters

    r = JSON.parse response.body

    expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
  end

  def no_other_users_user_subs_for_student(parameters)
    other_user = FactoryGirl.create(:user)
    other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

    get :index, parameters

    r = JSON.parse response.body

    expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
  end

  def no_other_users_own_subs_for_anyone(parameters)
    other_user = FactoryGirl.create(:user)
    other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

    get :index, parameters

    r = JSON.parse response.body

    expect(r.any? { |e| e['id'] == other_guys_sub.id && e['user_id'] == other_user.id }).to be(false), "shouldn't contain other submission's id or other user's id"
  end
end
