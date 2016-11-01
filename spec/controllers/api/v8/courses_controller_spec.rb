require "spec_helper"

describe Api::V8::CoursesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:course_name) { "testcourse" }
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}") }
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  before(:each) do
    controller.stub(:doorkeeper_token) { token }
  end

  describe "GET find_by_id" do

    describe "as admin" do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }

      describe "when course ID given" do
        it "shows course information" do
          get :find_by_id, id: course.id
          expect(response).to have_http_status(:success)
          expect(response.body).to have_content course.name
        end
      end
      describe "when hidden course's ID given" do
        it "shows course information" do
          course.hidden = true
          course.save!
          get :find_by_id, id: course.id
          expect(response).to have_http_status(:success)
          expect(response.body).to have_content course.name
        end
      end
      describe "when invalid course ID given" do
        it "shows error about finding course" do
          get :find_by_id, id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
    end

    describe "as user" do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      describe "when course ID given" do
        it "shows course information" do
          get :find_by_id, id: course.id
          expect(response).to have_http_status(:success)
          expect(response.body).to have_content course.name
        end
      end
      describe "when hidden course's ID given" do
        it "shows authorization error" do
          course.hidden = true
          course.save!
          get :find_by_id, id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "You are not authorized"
        end
      end
      describe "when invalid course ID given" do
        it "shows error about finding course" do
          get :find_by_id, id: -1
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
    end

    describe "as guest" do
      let(:token) { nil }

      describe "when course ID given" do
        it "shows authentication error" do
          get :find_by_id, id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
      describe "when hidden course's ID given" do
        it "shows authentication error" do
          course.hidden = true
          course.save!
          get :find_by_id, id: course.id
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
      describe "when invalid course ID given" do
        it "shows authentication error" do
          get :find_by_id, id: -1
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
    end

  end

  describe "GET find_by_id" do

    describe "when logged as admin" do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }

      describe "when organization id and course name given" do
        it "shows course information" do
          get :find_by_name, {slug: organization.slug, name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to have_content course.name
        end
      end
      describe "when hidden course's organization id and course name given" do
        it "shows course information" do
          course.hidden = true
          course.save!
          get :find_by_name, {slug: organization.slug, name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to have_content course.name
        end
      end
      describe "when invalid organization id and valid course name given" do
        it "error about finding course" do
          get :find_by_name, {slug: "bad", name: course_name}
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
      describe "when valid organization id and invalid course name given" do
        it "error about finding course" do
          get :find_by_name, {slug: organization.slug, name: "bad"}
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
      describe "when invalid organization id and invalid course name given" do
        it "error about finding course" do
          get :find_by_name, {slug: "bad", name: "bad"}
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
    end

    describe "when logged as user" do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      describe "when organization id and course name given" do
        it "shows course information" do
          get :find_by_name, {slug: organization.slug, name: course_name}
          expect(response).to have_http_status(:success)
          expect(response.body).to have_content course.name
        end
      end
      describe "when hidden course's organization id and course name given" do
        it "shows authorization error" do
          course.hidden = true
          course.save!
          get :find_by_name, {slug: organization.slug, name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "You are not authorized"
        end
      end
      describe "when invalid organization id and valid course name given" do
        it "shows error about finding course" do
          get :find_by_name, {slug: "bad", name: course_name}
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
      describe "when valid organization id and invalid course name given" do
        it "error about finding course" do
          get :find_by_name, {slug: organization.slug, name: "bad"}
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
      describe "when invalid organization id and invalid course name given" do
        it "error about finding course" do
          get :find_by_name, {slug: "bad", name: "bad"}
          expect(response).to have_http_status(:missing)
          expect(response.body).to have_content "Couldn't find Course"
        end
      end
    end

    describe "as guest" do
      let(:token) { nil }

      describe "when organization id and course name given" do
        it "shows authentication error" do
          get :find_by_name, {slug: organization.slug, name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
      describe "when hidden course's organization id and course name given" do
        it "shows authentication error" do
          course.hidden = true
          course.save!
          get :find_by_name, {slug: organization.slug, name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
      describe "when invalid organization id and valid course name given" do
        it "shows authentication error" do
          get :find_by_name, {slug: "bad", name: course_name}
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
      describe "when valid organization id and invalid course name given" do
        it "shows authentication error" do
          get :find_by_name, {slug: organization.slug, name: "bad"}
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
      describe "when invalid organization id and invalid course name given" do
        it "shows authentication error" do
          get :find_by_name, {slug: "bad", name: "bad"}
          expect(response).to have_http_status(403)
          expect(response.body).to have_content "Authentication required"
        end
      end
    end
  end
end
