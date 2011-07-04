require 'spec_helper'

describe User do

  def create_user
    User.create!(:login    => 'ohjaaja',
                 :password => 'ohjaaja')
  end

  describe "low level tests" do
    it "has none to begin with" do
      User.count.should == 0
    end
    
    it "has one after adding one" do
      user = create_user
      User.count.should == 1
    end

    it "has none after one was created in a previous example" do
      User.count.should == 0
    end
  end
  
  describe "validations" do
    describe "with valid params" do
      it "with valid login and password" do
        create_user.should have(0).errors_on(:login)
      end
    end
    
    describe "with invalid params" do
      it "should fail without login" do
        User.new(:password => "ohjaaja").should have(2).errors_on(:login)
      end
      
      it "should fail with too short login" do
        short_login = {:login => "a", :password => 'ohjaaja' }
        User.new(short_login).should have(1).errors_on(:login)
      end
        
      it "should fail with too long login" do
        long_login = {:login => "a"*21, :password => 'ohjaaja' }
        User.new(long_login).should have(1).errors_on(:login)
      end
      
      it "should fail without password" do
        User.new(:login => 'ohjaaja').should have(2).errors_on(:password)
      end
      
      it "should fail with too short password" do
        short_pass = {:login => "ohjaaja", :password => 'a' }
        User.new(short_pass).should have(1).errors_on(:password)
      end
      
      it "should fail with too long password" do
        long_pass = {:login => "ohjaaja", :password => 'o'*41 }
        User.new(long_pass).should have(1).errors_on(:password)
      end
    end
  end
  
  describe "methods" do
    describe "has_password return values" do
      it "should return true with valid password" do
        user = create_user
        user.has_password?("ohjaaja").should eq(true)
      end
      
      it "should return false with invalid password" do
        user = create_user
        user.has_password?("wrongpassword").should eq(false)
      end
    end
    
    describe "authenticate return values" do
      it "should return right user with valid login/password" do
        user = create_user
        User.authenticate("ohjaaja", "ohjaaja").should eq(user)
      end
      
      it "should return nil with invalid login/password" do
        user = create_user
        User.authenticate("wronglogin", "wronpassword").should eq(nil)
      end
    end
  end
end
