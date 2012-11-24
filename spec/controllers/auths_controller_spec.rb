require 'spec_helper'

describe AuthsController do
  before :each do
    @user = Factory.create(:user, :login => 'foo', :password => 'bar')
  end

  it "tells whether the given user/password is valid or not" do
    get :show, :username => 'foo', :password => 'bar', :format => 'text'
    response.should be_successful
    response.body.should == "OK"

    get :show, :username => 'foo', :password => 'wrong', :format => 'text'
    response.should be_successful
    response.body.should == "FAIL"

    get :show, :username => 'wrong', :password => 'bar', :format => 'text'
    response.should be_successful
    response.body.should == "FAIL"
  end

  it "should work with POST as well" do
    post :show, :username => 'foo', :password => 'bar', :format => 'text'
    response.should be_successful
    response.body.should == "OK"

    post :show, :username => 'foo', :password => 'wrong', :format => 'text'
    response.should be_successful
    response.body.should == "FAIL"

    post :show, :username => 'wrong', :password => 'bar', :format => 'text'
    response.should be_successful
    response.body.should == "FAIL"
  end

  it "should work with an existing session" do
    Session.create!(:session_id => 'foo', :data => {'user_id' => @user.id})
    s = Session.last
    s.should_not be_nil
    post :show, :username => 'foo', :session_id => s.session_id
    response.should be_successful
    response.body.should == "OK"
  end
end