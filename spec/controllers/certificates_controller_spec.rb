# frozen_string_literal: true

require 'spec_helper'

describe CertificatesController, type: :controller do
  before(:each) do
    @course = FactoryBot.create(:course)
  end
  describe 'GET index' do
    describe 'for regular users' do
      before :each do
        @user = FactoryBot.create(:user)
        controller.current_user = @user
      end
      it "should show only the current user's certificates" do
        other_user = FactoryBot.create(:user)
        my_cert = FactoryBot.create(:certificate, user: @user, course: @course)
        other_guys_cert = FactoryBot.create(:certificate, user: other_user, course: @course)

        get :index, params: { participant_id: @user.id }

        expect(assigns(:user).certificates).to include(my_cert)
        expect(assigns(:user).certificates).not_to include(other_guys_cert)
      end
      it "should not have access to other user's certificates" do
        other_user = FactoryBot.create(:user)

        get :index, params: { participant_id: other_user.id }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'for administrators' do
      before :each do
        @user = FactoryBot.create(:admin)
        controller.current_user = @user
      end
      it "should have access to other user's certificates" do
        other_user = FactoryBot.create(:user)
        other_guys_cert = FactoryBot.create(:certificate, user: other_user, course: @course)

        get :index, params: { participant_id: other_user.id }
        expect(assigns(:user).certificates).to include(other_guys_cert)
      end
    end
  end
end
