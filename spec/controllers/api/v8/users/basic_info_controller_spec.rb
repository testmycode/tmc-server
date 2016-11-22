require 'spec_helper'

describe Api::V8::Users::BasicInfoController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:other_user) { FactoryGirl.create(:user) }
  let!(:admin) { FactoryGirl.create(:admin) }

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe "GET current user's info with an access token" do
    let!(:token) { double resource_owner_id: user.id, acceptable?: true }
    it "user sees own info" do
      get :show

      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.username)
      expect(response.body).to include(user.email)
    end
    it "user doesn't see other users' infos" do
      get :show

      expect(response).to have_http_status(200)
      expect(response.body).not_to include(other_user.username)
      expect(response.body).not_to include(other_user.email)
    end
  end
  describe "GET user's info with user id" do
    describe "using user token" do
      let!(:token) { double resource_owner_id: user.id, acceptable?: true }
      it "user sees own info" do
        get :show, user_id: user.id

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.username)
        expect(response.body).to include(user.email)
      end
      it "user doesn't see other users' infos" do
        get :show, user_id: other_user.id

        expect(response).to have_http_status(403)
        expect(response.body).not_to include(other_user.username)
        expect(response.body).not_to include(other_user.email)
      end
    end
    describe "using admin token" do
      let!(:token) { double resource_owner_id: admin.id, acceptable?: true }
      it "admin can see everyone's infos" do
        get :show, user_id: user.id

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.username)
        expect(response.body).to include(user.email)

        get :show, user_id: other_user.id

        expect(response).to have_http_status(:success)
        expect(response.body).to include(other_user.username)
        expect(response.body).to include(other_user.email)
      end
    end
    describe "when admin is logged in" do
      before :each do
        controller.current_user = admin
      end
      it "they can see users' infos" do
        get :show, user_id: user.id

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.username)
        expect(response.body).to include(user.email)

        get :show, user_id: other_user.id

        expect(response).to have_http_status(:success)
        expect(response.body).to include(other_user.username)
        expect(response.body).to include(other_user.email)
      end
    end
    describe "when a student is logged in" do
      before :each do
        controller.current_user = user
      end
      it "they can see their own info" do
        get :show, user_id: user.id

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user.username)
        expect(response.body).to include(user.email)
      end
      it "they can't see other users' infos" do
        get :show, user_id: other_user.id

        expect(response).to have_http_status(403)
        expect(response.body).not_to include(other_user.username)
        expect(response.body).not_to include(other_user.email)
      end
    end
    describe "when an unauthorized user tries to see infos" do
      before :each do
        controller.current_user = Guest.new
      end
      it "they get an error message" do
        get :show, user_id: user.id

        expect(response).to have_http_status(403)
        expect(response.body).to include("Authentication required")
      end
    end
  end
end
