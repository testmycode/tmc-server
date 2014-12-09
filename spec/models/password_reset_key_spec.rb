require 'spec_helper'

describe PasswordResetKey, :type => :model do
  before :each do
    @user = FactoryGirl.create(:user)
    @way_in_the_past = Time.now - 3.days
  end

  it "should get a random code by default" do
    code1 = PasswordResetKey.create!(:user => @user).code
    @user.password_reset_key.destroy
    code2 = PasswordResetKey.create!(:user => @user).code
    expect(code1).not_to be_blank
    expect(code1).not_to eq(code2)
  end

  it "should only exist at most once per user" do
    PasswordResetKey.create!(:user => @user)

    password_reset_key = PasswordResetKey.new(:user => @user)
    expect(password_reset_key).not_to be_valid
    expect(password_reset_key.errors[:user_id].size).to eq(1)
  end

  it "should be destroyed when the user is destroyed" do
    key_id = PasswordResetKey.create!(:user => @user).id
    @user.destroy
    expect(PasswordResetKey.where(:id => key_id)).to be_empty
  end

  it "should be considered expired when it's more than a day old" do
    key = PasswordResetKey.create!(:user => @user)
    expect(key).not_to be_expired
    key.created_at = Time.now - 17.hours
    expect(key).not_to be_expired
    key.created_at = Time.now - 25.hours
    expect(key).to be_expired
  end

  describe "#generate_for(user)" do
    it "should generate a new key" do
      PasswordResetKey.generate_for(@user)
      @user.reload
      expect(@user.password_reset_key).not_to be_nil
      expect(@user.password_reset_key.code).not_to be_blank
    end

    it "should destroy any old key first" do
      old_key = PasswordResetKey.create!(:user => @user)

      PasswordResetKey.generate_for(@user)
      @user.reload
      expect(@user.password_reset_key.code).not_to eq(old_key.code)
    end
  end
end
