require 'spec_helper'

describe Api::V8::SubmissionsController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:admin) { FactoryGirl.create(:admin) }
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let(:course_name) { 'testcourse'}
  let(:course_name_with_slug) { "#{organization.slug}-#{course_name}" }
  let!(:course) { FactoryGirl.create(:course, name: "#{course_name_with_slug}", organization: organization) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) { FactoryGirl.create(:submission,
  course: course,
  user: user,
  exercise: exercise)}
  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe "GET all submissions" do
    describe "by course name as json" do
      describe "as an admin" do
        describe "when logged in" do
          before :each do
            controller.current_user = admin
          end

          it "should show all of the submissions" do
            get_two_subs_by_name
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: admin.id, acceptable?: true }

          it "should show all of the submissions" do
            get_two_subs_by_name
          end
        end
      end

      describe "as a teacher" do
        before :each do
          Teachership.create(user: user, organization: organization)
        end

        describe "when logged in" do
          before :each do
            controller.current_user = user
          end

          it "should show all of the submissions in my organizations" do
            get_two_subs_by_name
          end

          it "should not show any submissions outside my organizations" do
            other_organization = FactoryGirl.create(:accepted_organization)
            other_course = FactoryGirl.create(:course, organization: other_organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it "should show all of the submissions in my organizations" do
            get_two_subs_by_name
          end

          it "should not show any submissions outside my organizations" do
            other_organization = FactoryGirl.create(:accepted_organization)
            other_course = FactoryGirl.create(:course, organization: other_organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end
      end

      describe "as an assistant" do
        before :each do
          Assistantship.create(user: user, course: course)
        end

        describe "when logged in" do
          before :each do
            controller.current_user = user
          end

          it "should show all of the submissions in my courses" do
            get_two_subs_by_name
          end

          it "should not show any submissions outside my courses" do
            other_course = FactoryGirl.create(:course, organization: organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it "should show all of the submissions in my courses" do
            get_two_subs_by_name
          end

          it "should not show any submissions outside my courses" do
            other_course = FactoryGirl.create(:course, organization: organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end
      end

      describe "as a student" do
        describe "when logged in" do
          before :each do
            controller.current_user = user
          end

          it "should show my own submissions" do
            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).to have_content("\"user_id\"=>#{user.id}")
            expect(json).to have_content("\"id\"=>#{submission.id}")
          end

          it "should not show other users' submissions" do
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it "should show my own submissions" do
            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).to have_content("\"user_id\"=>#{user.id}")
            expect(json).to have_content("\"id\"=>#{submission.id}")
          end

          it "should not show other users' submissions" do
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

            get :all_submissions, slug: organization.slug, course_name: course_name

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end
      end

      describe "as an unauthorized user" do
        before :each do
          controller.current_user = Guest.new
        end

        it "should not show any submissions" do
          get :all_submissions, slug: organization.slug, course_name: course_name

          json = JSON.parse response.body

          expect(json).to have_content("You are not signed in!")
        end
      end
    end

    describe "by course id as json" do
      describe "as an admin" do
        describe "when logged in" do
          before :each do
            controller.current_user = admin
          end

          it "should show all of the submissions" do
            get_two_subs_by_id
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: admin.id, acceptable?: true }

          it "should show all of the submissions" do
            get_two_subs_by_id
          end
        end
      end

      describe "as a teacher" do
        before :each do
          Teachership.create(user: user, organization: organization)
        end

        describe "when logged in" do
          before :each do
            controller.current_user = user
          end

          it "should show all of the submissions in my organizations" do
            get_two_subs_by_id
          end

          it "should not show any submissions outside my organizations" do
            other_organization = FactoryGirl.create(:accepted_organization)
            other_course = FactoryGirl.create(:course, organization: other_organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it "should show all of the submissions in my organizations" do
            get_two_subs_by_id
          end

          it "should not show any submissions outside my organizations" do
            other_organization = FactoryGirl.create(:accepted_organization)
            other_course = FactoryGirl.create(:course, organization: other_organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end
      end

      describe "as an assistant" do
        before :each do
          Assistantship.create(user: user, course: course)
        end

        describe "when logged in" do
          before :each do
            controller.current_user = user
          end

          it "should show all of the submissions in my courses" do
            get_two_subs_by_id
          end

          it "should not show any submissions outside my courses" do
            other_course = FactoryGirl.create(:course, organization: organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it "should show all of the submissions in my courses" do
            get_two_subs_by_id
          end

          it "should not show any submissions outside my courses" do
            other_course = FactoryGirl.create(:course, organization: organization)
            other_exercise = FactoryGirl.create(:exercise, course: other_course)
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end
      end

      describe "as a student" do
        describe "when logged in" do
          before :each do
            controller.current_user = user
          end

          it "should show my own submissions" do
            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).to have_content("\"user_id\"=>#{user.id}")
            expect(json).to have_content("\"id\"=>#{submission.id}")
          end

          it "should not show other users' submissions" do
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end

        describe "when using access token" do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it "should show my own submissions" do
            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).to have_content("\"user_id\"=>#{user.id}")
            expect(json).to have_content("\"id\"=>#{submission.id}")
          end

          it "should not show other users' submissions" do
            other_user = FactoryGirl.create(:user)
            other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

            get :all_submissions, course_id: course.id

            json = JSON.parse response.body

            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
            expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
          end
        end
      end

      describe "as an unauthorized user" do
        before :each do
          controller.current_user = Guest.new
        end

        it "should not show any submissions" do
          get :all_submissions, course_id: course.id

          json = JSON.parse response.body

          expect(json).to have_content("You are not signed in!")
        end
      end
    end
  end

  describe "GET single user's submissions by course id as json" do
    describe "as an admin" do
      describe "when logged in" do
        before :each do
          controller.current_user = admin
        end

        it "should show given user's submissions" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end
      end

      describe "when using access token" do
        let!(:token) { double resource_owner_id: admin.id, acceptable?: true }

        it "should show given user's submissions" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end
      end
    end

    describe "as a teacher" do
      before :each do
        Teachership.create(user: user, organization: organization)
      end

      describe "when logged in" do
        before :each do
          controller.current_user = user
        end

        it "should show given user's submissions in my organizations" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show any submissions outside my organizations" do
          other_organization = FactoryGirl.create(:accepted_organization)
          other_course = FactoryGirl.create(:course, organization: other_organization)
          other_exercise = FactoryGirl.create(:exercise, course: other_course)
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end

      describe "when using access token" do
        let!(:token) { double resource_owner_id: user.id, acceptable?: true }

        it "should show given user's submissions in my organizations" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show any submissions outside my organizations" do
          other_organization = FactoryGirl.create(:accepted_organization)
          other_course = FactoryGirl.create(:course, organization: other_organization)
          other_exercise = FactoryGirl.create(:exercise, course: other_course)
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end
    end

    describe "as an assistant" do
      before :each do
        Assistantship.create(user: user, course: course)
      end

      describe "when logged in" do
        before :each do
          controller.current_user = user
        end

        it "should show given user's submissions in my courses" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show any submissions outside my courses" do
          other_course = FactoryGirl.create(:course, organization: organization)
          other_exercise = FactoryGirl.create(:exercise, course: other_course)
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end

      describe "when using access token" do
        let!(:token) { double resource_owner_id: user.id, acceptable?: true }

        it "should show given user's submissions in my courses" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show any submissions outside my courses" do
          other_course = FactoryGirl.create(:course, organization: organization)
          other_exercise = FactoryGirl.create(:exercise, course: other_course)
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end
    end

    describe "as a student" do
      describe "when logged in" do
        before :each do
          controller.current_user = user
        end

        it "should show my own submissions" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show other users' submissions" do
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end

      describe "when using access token" do
        let!(:token) { double resource_owner_id: user.id, acceptable?: true }

        it "should show my own submissions" do
          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show other users' submissions" do
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

          get :users_submissions, course_id: course.id, user_id: user.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end
    end

    describe "as an unauthorized user" do
      before :each do
        controller.current_user = Guest.new
      end

      it "should not show any submissions" do
        get :users_submissions, course_id: course.id, user_id: user.id

        json = JSON.parse response.body

        expect(json).to have_content("[\"You are not authorized to access this page.\"]")
      end
    end
  end

  describe "GET user's own submissions by course id as json" do
    describe "as an user" do
      describe "when logged in" do
        before :each do
          controller.current_user = user
        end

        it "should show my own submissions" do
          get :my_submissions, course_id: course.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show other users' submissions" do
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

          get :my_submissions, course_id: course.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end

      describe "when using access token" do
        let!(:token) { double resource_owner_id: user.id, acceptable?: true }

        it "should show my own submissions" do
          get :my_submissions, course_id: course.id

          json = JSON.parse response.body

          expect(json).to have_content("\"user_id\"=>#{user.id}")
          expect(json).to have_content("\"id\"=>#{submission.id}")
        end

        it "should not show other users' submissions" do
          other_user = FactoryGirl.create(:user)
          other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: course)

          get :my_submissions, course_id: course.id

          json = JSON.parse response.body

          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.id}")
          expect(json).not_to have_content("\"id\"=>#{other_guys_sub.user.id}")
        end
      end
    end

    describe "as an unauthorized user" do
      before :each do
        controller.current_user = Guest.new
      end

      it "should not show any submissions" do
        get :my_submissions, course_id: course.id

        json = JSON.parse response.body

        expect(json).to have_content("You are not signed in!")
      end
    end
  end

  private

  def get_two_subs_by_name
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    sub1 = FactoryGirl.create(:submission, user: user1, course: course)
    sub2 = FactoryGirl.create(:submission, user: user2, course: course)

    get :all_submissions, slug: organization.slug, course_name: course_name

    json = JSON.parse response.body

    expect(json).to have_content("\"user_id\"=>#{user1.id}")
    expect(json).to have_content("\"user_id\"=>#{user2.id}")
    expect(json).to have_content("\"id\"=>#{sub1.id}")
    expect(json).to have_content("\"id\"=>#{sub2.id}")
  end

  def get_two_subs_by_id
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    sub1 = FactoryGirl.create(:submission, user: user1, course: course)
    sub2 = FactoryGirl.create(:submission, user: user2, course: course)

    get :all_submissions, course_id: course.id

    json = JSON.parse response.body

    expect(json).to have_content("\"user_id\"=>#{user1.id}")
    expect(json).to have_content("\"user_id\"=>#{user2.id}")
    expect(json).to have_content("\"id\"=>#{sub1.id}")
    expect(json).to have_content("\"id\"=>#{sub2.id}")
  end
end
