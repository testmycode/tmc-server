require 'spec_helper'

describe SessionsController do

  def valid_attributes
    { :login    => 'ohjaaja',
      :password => 'ohjaaja' }
  end

  describe "POST create" do
    describe "with valid params" do
      it "it assigns new user to @current_user" do
        post :create, :session => valid_attributes
        assigns(:session).should eq(@current_user)
      end
      
      it "after login it redirects to current page" do
        post :create, :session => valid_attributes
        response.should render_template(request.env["HTTP_REFERER"]) # :back doesn't work (:back is short for request.env["HTTP_REFERER"])
      end
    end
    
    describe "with invalid params" do
      it "login is incorrect" do
        post :create, :session => { :password => 'ohjaaja' }
        assigns(:session).should eq(nil)
      end
      
      it "password is incorrect for correct login" do
        post :create, :session => { :login    => 'ohjaaja', 
                                    :password => 'iswrong' }
        assigns(:session).should eq(nil)
      end
      
      it "redirects to same page" do
        post :create, :session => {}
        response.should render_template(request.env["HTTP_REFERER"])
      end
    end
  end
  
  describe "DELETE destroy" do
    before(:each) do
      post :create, :session => valid_attributes
    end
  
    it "assign @current_user to nil" do
      :destroy
      assigns(:session).should eq(nil)
    end
    
    it "redirects to same page" do
      :destroy
      response.should render_template(request.env["HTTP_REFERER"])
    end
  end
end
