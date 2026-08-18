# frozen_string_literal: true

require 'spec_helper'

describe ParticipantsController, type: :controller do
  before :each do
    @user = FactoryBot.create(:user)
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
        expect(response.headers['Location']).to include('login?return_to=%2Fparticipants%2Fme')
      end
    end
  end

  describe 'POST /force_migrate_to_courses_mooc_fi' do
    describe 'when logged in as a non-admin' do
      before :each do
        controller.current_user = @user
      end

      it 'is forbidden' do
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'when logged in as an admin' do
      before :each do
        controller.current_user = FactoryBot.create(:admin)
      end

      it 'is forbidden when the target user is an admin' do
        admin_target = FactoryBot.create(:admin)
        expect_any_instance_of(User).not_to receive(:force_migrate_to_courses_mooc_fi)
        post :force_migrate_to_courses_mooc_fi, params: { id: admin_target.id }
        expect(response.code.to_i).to eq(403)
      end

      it 'refuses when the user is already managed externally' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).not_to receive(:force_migrate_to_courses_mooc_fi)
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:alert]).to match(/already managed/)
      end

      it 'migrates the user when they are not yet managed externally and the migration succeeds' do
        expect_any_instance_of(User).to receive(:force_migrate_to_courses_mooc_fi).and_return({ success: true })
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:notice]).to match(/force-migrated/)
      end

      it 'shows the exact error when the migration fails' do
        expect_any_instance_of(User).to receive(:force_migrate_to_courses_mooc_fi).and_return({ success: false, error: 'status=422, body={"error"=>"boom"}' })
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:alert]).to match(/status=422/)
      end
    end
  end
end
