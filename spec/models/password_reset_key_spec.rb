require 'spec_helper'

describe PasswordResetKey do
  before :each do
    @user = Factory.create(:user)
    @way_in_the_past = Time.now - 3.days
  end

  it "should get a random code by default" do
    code1 = PasswordResetKey.create!(:user => @user).code
    @user.password_reset_key.destroy
    code2 = PasswordResetKey.create!(:user => @user).code
    code1.should_not be_blank
    code1.should_not == code2
  end

  it "should only exist at most once per user" do
    PasswordResetKey.create!(:user => @user)
    PasswordResetKey.new(:user => @user).should have(1).error_on(:user_id)
  end
  
  it "should be destroyed when the user is destroyed" do
    key_id = PasswordResetKey.create!(:user => @user).id
    @user.destroy
    PasswordResetKey.where(:id => key_id).should be_empty
  end
  
  it "should be considered expired when it's more than a day old" do
    key = PasswordResetKey.create!(:user => @user)
    key.should_not be_expired
    key.created_at = Time.now - 17.hours
    key.should_not be_expired
    key.created_at = Time.now - 25.hours
    key.should be_expired
  end
  
  describe "#generate_for(user)" do
    it "should generate a new key" do
      PasswordResetKey.generate_for(@user)
      @user.reload
      @user.password_reset_key.should_not be_nil
      @user.password_reset_key.code.should_not be_blank
    end
    
    it "should destroy any old key first" do
      old_key = PasswordResetKey.create!(:user => @user)
    
      PasswordResetKey.generate_for(@user)
      @user.reload
      @user.password_reset_key.code.should_not == old_key.code
    end
  end
end
