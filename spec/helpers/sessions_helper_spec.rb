require 'spec_helper'

describe SessionsHelper do
  
  let!(:user) { Factory.create(:user) }
  
  describe "#sign_in" do
    it "should assign user to @current_user" do
      sign_in(user).should eq(@current_user)
    end
  end
    
  describe "#current_user" do
    it "should return the current_user when signed in" do
      sign_in(user)
      current_user.should eq(user)
    end
    
    it "should return a guest user when not signed in" do
      current_user.should be_guest
    end 
  end
  
  describe "#signed_in?" do
    it "should return true if user is signed in" do
      sign_in(user)
      signed_in?.should eq(true)
    end
    
    it "should return false if use is not signed in" do
      signed_in?.should eq(false)
    end
  end
  
  describe "#sign_out" do
    it "should assign current_user to guest and reset the session" do
      sign_in(user)
      
      self.should_receive(:reset_session)
      sign_out
      current_user.should be_guest
    end
  end
end
