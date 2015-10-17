require 'spec_helper'

describe SessionsController, type: :controller do
  before :each do
    @user = mock_model(User, administrator: true, email_confirmed_at: Time.now)
    allow(User).to receive(:authenticate) do |login, pwd|
      @user if login == 'instructor' && pwd == 'correct_password'
    end
  end

  def post_create
    session_attrs = {
      login: 'instructor',
      password: 'correct_password'
    }
    post :create, session: session_attrs
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'should set the current user' do
        post_create
        expect(controller.send(:current_user)).to be(@user)
      end

      it 'should redirect back to the current page if there is a referer' do
        request.env['HTTP_REFERER'] = '/xooxers'
        post_create
        expect(response).to redirect_to('/xooxers')
      end

      it 'should redirect back to the home page if there is no referer' do
        request.env['HTTP_REFERER'] = nil
        post_create
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'when authentication fails' do
      before :each do
        allow(User).to receive_messages(authenticate: nil)
      end

      it 'should not set current_user' do
        post_create
        expect(controller.send(:current_user)).to be_guest
      end

      it 'should redirect back to the current page if there is a referer' do
        request.env['HTTP_REFERER'] = '/xooxers'
        post_create
        expect(response).to redirect_to('/xooxers')
      end

      it 'should redirect to the home page if there is no referer' do
        request.env['HTTP_REFERER'] = nil
        post_create
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE destroy' do
    before(:each) do
      post_create
      expect(controller.send(:current_user)).to be(@user)
    end

    it 'should clear current_user and the session' do
      post :destroy
      session.delete(:flash) # Flash will not be discarded without a render
      expect(controller.send(:current_user)).to be_guest
      expect(session).to be_empty
    end

    it 'should redirect back to the current page if there is a referer' do
      request.env['HTTP_REFERER'] = '/xooxers'
      post :destroy
      expect(response).to redirect_to('/xooxers')
    end

    it 'should redirects to the home page if there is no referer' do
      request.env['HTTP_REFERER'] = nil
      post :destroy
      expect(response).to redirect_to(root_path)
    end
  end
end
