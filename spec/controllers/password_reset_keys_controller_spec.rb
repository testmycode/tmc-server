# frozen_string_literal: true

require 'spec_helper'

describe PasswordResetKeysController, type: :controller do
  describe 'DELETE destroy' do
    before :each do
      @user = FactoryBot.create(:user)
      @key = ActionToken.generate_password_reset_key_for(@user)
    end

    def do_destroy
      delete :destroy, params: { token: @key.token, password: 'new_password', password_confirmation: 'new_password' }
    end

    describe 'for a user not yet managed by courses.mooc.fi' do
      it 'resets the local password and migrates the user to courses.mooc.fi' do
        expect_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).with('new_password').and_return(true)

        do_destroy

        expect(response).to redirect_to(root_path)
        expect(@user.reload).to have_password('new_password')
        expect(ActionToken.find_by(id: @key.id)).to be_nil
      end

      it 'still resets the password when migration fails' do
        expect_any_instance_of(User).to receive(:post_new_user_to_courses_mooc_fi).with('new_password').and_return(false)

        do_destroy

        expect(response).to redirect_to(root_path)
        expect(@user.reload).to have_password('new_password')
      end
    end

    describe 'for a user managed by courses.mooc.fi' do
      before :each do
        @user.update!(password_managed_by_courses_mooc_fi: true, courses_mooc_fi_user_id: SecureRandom.uuid)
      end

      it 'delegates the reset to courses.mooc.fi without migrating' do
        expect_any_instance_of(User).to receive(:update_password_via_courses_mooc_fi).with(nil, 'new_password').and_return(true)
        expect_any_instance_of(User).not_to receive(:post_new_user_to_courses_mooc_fi)

        do_destroy

        expect(response).to redirect_to(root_path)
        expect(ActionToken.find_by(id: @key.id)).to be_nil
      end
    end
  end
end
