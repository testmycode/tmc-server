require 'spec_helper'

describe SessionsHelper do
  
  def create_user
    User.new(:login    => 'ohjaaja',
             :password => 'ohjaaja')
  end
  
  describe "sign_in" do
    it "should assign user to @current_user" do
      user = create_user
      sign_in(user).should eq(@current_user)
    end
  end
    
  describe "current_user" do
    it "should return @current_user if one exists" do
      user = create_user
      sign_in(user)
      current_user.should eq(user)
    end
    
    it "should return nil if one doesn't exist" do
      current_user.should eq(nil)
    end 
  end
  
  describe "signed_in?" do
    it "should return true if user is signed in" do
      user = create_user
      sign_in(user)
      signed_in?.should eq(true)
    end
    
    it "should return false if use is not signed in" do
      signed_in?.should eq(false)
    end
  end
  
  describe "sign_out" do
    it "should assign @current_user to nil and reset the session" do
      user = create_user
      sign_in(user).should eq(@current_user)
      
      self.should_receive(:reset_session)
      sign_out
      @current_user.should eq(nil)
    end
  end
end
