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

      it 'refuses when the user is already managed externally and courses.mooc.fi confirms the account is live' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: true, courses_mooc_fi_user_id: @user.courses_mooc_fi_user_id, password_set: true, deleted_at: nil }
        )
        expect_any_instance_of(User).not_to receive(:force_migrate_to_courses_mooc_fi)
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:alert]).to match(/already managed/)
      end

      it 'refuses when the user is already managed externally and the live status is unknown' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(nil)
        expect_any_instance_of(User).not_to receive(:force_migrate_to_courses_mooc_fi)
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:alert]).to match(/already managed/)
      end

      it 'allows re-migrating when managed externally locally but courses.mooc.fi confirms the account is gone' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: false, courses_mooc_fi_user_id: nil, password_set: false, deleted_at: nil }
        )
        expect_any_instance_of(User).to receive(:force_migrate_to_courses_mooc_fi).and_return({ success: true, courses_mooc_fi_user_id: 'new-id' })
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:notice]).to match(/force-migrated/)
      end

      it 'allows re-migrating when managed externally locally but the linked courses.mooc.fi account was deleted' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: true, courses_mooc_fi_user_id: @user.courses_mooc_fi_user_id, password_set: false, deleted_at: Time.current }
        )
        expect_any_instance_of(User).to receive(:force_migrate_to_courses_mooc_fi).and_return({ success: true, courses_mooc_fi_user_id: 'new-id' })
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:notice]).to match(/force-migrated/)
      end

      it 'migrates the user when they are not yet managed externally and the migration succeeds' do
        expect_any_instance_of(User).to receive(:force_migrate_to_courses_mooc_fi).and_return({ success: true, courses_mooc_fi_user_id: 'abc-123' })
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:notice]).to match(/force-migrated/)
        expect(flash[:notice]).to match(/abc-123/)
      end

      it 'shows the exact error when the migration fails' do
        expect_any_instance_of(User).to receive(:force_migrate_to_courses_mooc_fi).and_return({ success: false, error: 'status=422, body={"error"=>"boom"}' })
        post :force_migrate_to_courses_mooc_fi, params: { id: @user.id }
        expect(response).to redirect_to(participant_path(@user))
        expect(flash[:alert]).to match(/status=422/)
      end
    end
  end

  describe 'GET /show' do
    describe 'when logged in as an admin' do
      before :each do
        controller.current_user = FactoryBot.create(:admin)
      end

      it 'shows the migration status when courses.mooc.fi confirms the user is not migrated' do
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: false, courses_mooc_fi_user_id: nil, password_set: false, deleted_at: nil }
        )
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to eq('Not migrated')
      end

      it 'flags an inconsistency when courses.mooc.fi already has a password but the user is not linked locally' do
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: true, courses_mooc_fi_user_id: SecureRandom.uuid, password_set: true, deleted_at: nil }
        )
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to match(/Inconsistent/)
      end

      it 'shows fully migrated when the user is already managed externally and courses.mooc.fi confirms the account is live' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: true, courses_mooc_fi_user_id: @user.courses_mooc_fi_user_id, password_set: true, deleted_at: nil }
        )
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to eq('Fully migrated')
        expect(assigns(:courses_mooc_fi_force_migrate_available)).to eq(false)
      end

      it 'shows fully migrated when the user is already managed externally and the live status is unknown' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(nil)
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to eq('Fully migrated')
        expect(assigns(:courses_mooc_fi_force_migrate_available)).to eq(false)
      end

      it 'flags drift and re-enables force migrate when locally managed but courses.mooc.fi has no live account' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: false, courses_mooc_fi_user_id: nil, password_set: false, deleted_at: nil }
        )
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to match(/Broken/)
        expect(assigns(:courses_mooc_fi_force_migrate_available)).to eq(true)
      end

      it 'flags drift and re-enables force migrate when the linked courses.mooc.fi account was deleted' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(
          { shadow_user_exists: true, courses_mooc_fi_user_id: @user.courses_mooc_fi_user_id, password_set: false, deleted_at: Time.current }
        )
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to match(/Broken/)
        expect(assigns(:courses_mooc_fi_force_migrate_available)).to eq(true)
      end

      it 'flags the broken state when managed locally but missing the target id' do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: nil)
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(nil)
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status_label)).to match(/Broken/)
      end

      it 'degrades gracefully when courses.mooc.fi cannot be reached' do
        expect_any_instance_of(User).to receive(:courses_mooc_fi_migration_status).and_return(nil)
        get :show, params: { id: @user.id }
        expect(response).to be_successful
        expect(assigns(:courses_mooc_fi_status)).to be_nil
        expect(assigns(:courses_mooc_fi_status_label)).to eq('Not migrated')
      end
    end
  end
end
