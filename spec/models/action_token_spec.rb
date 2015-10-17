require 'spec_helper'

describe ActionToken, type: :model do

  describe 'for email confirmantion' do
    before :each do
      @user = User.create!(login: 'test', email: 'test@test.com')
    end

    describe '#generate_email_confirmation_token_for(user)' do
      it 'should generate a new key' do
        ActionToken.generate_email_confirmation_token(@user)
        @user.reload
        expect(@user.email_confirmation_token).not_to be_nil
        expect(@user.email_confirmation_token.token).not_to be_blank
      end

      it 'should use old key if it exist' do
        key = ActionToken.create!(user: @user, action: :confirm_email)
        ActionToken.generate_email_confirmation_token(@user)
        @user.reload
        expect(@user.email_confirmation_token.token).to eq(key.token)
      end
    end
  end

  describe 'for password_reset_key' do
    before :each do
      @user = FactoryGirl.create(:user)
      @way_in_the_past = Time.now - 3.days
    end

    it 'should get a random token by default' do
      token1 = ActionToken.create!(user: @user, action: :reset_password).token
      @user.password_reset_key.destroy
      token2 = ActionToken.create!(user: @user, action: :reset_password).token
      expect(token1).not_to be_blank
      expect(token1).not_to eq(token2)
    end

    it 'should only exist at most once per user' do
      ActionToken.create!(user: @user, action: :reset_password)

      password_reset_key = ActionToken.new(user: @user, action: :reset_password)
      expect(password_reset_key).not_to be_valid
      expect(password_reset_key.errors[:user_id].size).to eq(1)
    end

    it 'should be destroyed when the user is destroyed' do
      key_id = ActionToken.create!(user: @user, action: :reset_password).id
      @user.destroy
      expect(ActionToken.where(id: key_id)).to be_empty
    end

    it "should be expired when expires_at time is passed" do
      key = ActionToken.create!(user: @user, action: :reset_password, expires_at: Time.now + 24.hours)
      expect(key).not_to be_expired
      key.expires_at = Time.now - 1.minute
      expect(key).to be_expired
    end

    describe '#generate_password_reset_key_for(user)' do
      it 'should generate a new key' do
        ActionToken.generate_password_reset_key_for(@user)
        @user.reload
        expect(@user.password_reset_key).not_to be_nil
        expect(@user.password_reset_key.token).not_to be_blank
      end

      it 'should destroy any old key first' do
        old_key = ActionToken.create!(user: @user, action: :reset_password)

        ActionToken.generate_password_reset_key_for(@user)
        @user.reload
        expect(@user.password_reset_key.token).not_to eq(old_key.token)
      end
    end
  end
end
