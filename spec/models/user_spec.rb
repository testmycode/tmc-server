require 'spec_helper'

describe User do

  describe "validation" do
    it "should succeed given a valid login and password" do
      User.new(:login => 'matt', :password => 'horner').should have(0).errors_on(:login)
    end
  
    it "should fail without login" do
      User.new(:password => "instructor").should have(2).errors_on(:login)
    end
    
    it "should fail with too short a login" do
      short_login = {:login => "a", :password => 'instructor' }
      User.new(short_login).should have(1).error_on(:login)
    end
      
    it "should fail with too long a login" do
      long_login = {:login => "a"*21, :password => 'instructor' }
      User.new(long_login).should have(1).error_on(:login)
    end
    
    it "should succeed without a password for new records" do
      User.new(:login => 'instructor').should be_valid
    end
    
    it "should succeed without a password for existing records" do
      User.create!(:login => 'instructor', :password => 'cookiestastegood')
      user = User.find_by_login!('instructor')
      user.password.should be_nil
      user.should be_valid
      user.save!
    end
    
    it "should fail with too short a password" do
      short_pass = {:login => "instructor", :password => 'a' }
      User.new(short_pass).should have(1).errors_on(:password)
    end
  end
  
  it "should hash the password on save" do
    User.create!(:login => "instructor", :password => "ilikecookies")
    user = User.find_by_login!("instructor")
    user.password.should be_nil
    user.password_hash.should_not be_nil
    user.should have_password("ilikecookies")
    user.should_not have_password("ihatecookies")
  end
  
  it "should allow authentication of administrators with a correct login/password" do
    user = User.create!(:login => "instructor", :password => "ilikecookies", :administrator => true)
    User.authenticate("instructor", "ilikecookies").should eq(user)
    User.authenticate("instructor", "ihatecookies").should be_nil
    User.authenticate("root", "ilikecookies").should be_nil
  end
end
