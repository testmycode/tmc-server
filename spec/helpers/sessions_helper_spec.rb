require 'spec_helper'

describe SessionsHelper, type: :helper do
  let!(:user) { FactoryGirl.create(:user) }

  describe '#sign_in' do
    it 'should assign user to @current_user' do
      expect(sign_in(user)).to eq(@current_user)
    end
  end

  describe '#current_user' do
    it 'should return the current_user when signed in' do
      sign_in(user)
      expect(current_user).to eq(user)
    end

    it 'should return a guest user when not signed in' do
      expect(current_user).to be_guest
    end
  end

  describe '#signed_in?' do
    it 'should return true if user is signed in' do
      sign_in(user)
      expect(signed_in?).to eq(true)
    end

    it 'should return false if use is not signed in' do
      expect(signed_in?).to eq(false)
    end
  end

  describe '#sign_out' do
    it 'should assign current_user to guest and reset the session' do
      sign_in(user)

      expect(self).to receive(:reset_session)
      sign_out
      expect(current_user).to be_guest
    end
  end
end
