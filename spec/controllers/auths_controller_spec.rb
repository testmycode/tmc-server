require 'spec_helper'

describe AuthsController, :type => :controller do
  before :each do
    @user = Factory.create(:user, :login => 'foo', :password => 'bar')
  end

  it "tells whether the given user/password is valid or not" do
    get :show, :username => 'foo', :password => 'bar', :format => 'text'
    expect(response).to be_successful
    expect(response.body).to eq("OK")

    get :show, :username => 'foo', :password => 'wrong', :format => 'text'
    expect(response).to be_successful
    expect(response.body).to eq("FAIL")

    get :show, :username => 'wrong', :password => 'bar', :format => 'text'
    expect(response).to be_successful
    expect(response.body).to eq("FAIL")
  end

  it "should work with POST as well" do
    post :show, :username => 'foo', :password => 'bar', :format => 'text'
    expect(response).to be_successful
    expect(response.body).to eq("OK")

    post :show, :username => 'foo', :password => 'wrong', :format => 'text'
    expect(response).to be_successful
    expect(response.body).to eq("FAIL")

    post :show, :username => 'wrong', :password => 'bar', :format => 'text'
    expect(response).to be_successful
    expect(response.body).to eq("FAIL")
  end

  it "should work with an existing session" do
    Session.create!(:session_id => 'foo', :data => {'user_id' => @user.id})
    s = Session.last
    expect(s).not_to be_nil
    post :show, :username => 'foo', :session_id => s.session_id
    expect(response).to be_successful
    expect(response.body).to eq("OK")
  end
end