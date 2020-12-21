# frozen_string_literal: true

require 'spec_helper'

describe ParticipantsController, type: :controller do
  before :each do
    @user = FactoryGirl.create(:user)
  end

  describe 'GET /me' do
    describe 'when logged in' do
      before :each do
        controller.current_user = @user
      end

      it 'redirects to current participant page' do
        get :me
        expect(response).to redirect_to(participant_path(@user))
      end
    end

    describe 'when not logged in' do
      it 'redirects me to login page' do
        get :me
        expect(response.code.to_i).to eq(302)
        expect(response.body).to include('login?return_to=%2Fparticipants%2Fme')
      end
    end
  end
end
