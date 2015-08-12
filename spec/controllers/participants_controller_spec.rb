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
        response.should redirect_to participant_path @user
      end
    end

    describe 'when not logged in' do
      it 'shows me access denied' do
        get :me
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
