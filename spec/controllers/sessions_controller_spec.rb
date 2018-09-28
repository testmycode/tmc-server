# frozen_string_literal: true

require 'spec_helper'

describe SessionsController, type: :controller do
  before :each do
    @user = mock_model(User, administrator?: true)
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

  describe 'GET new' do
    context 'when logged in' do
      before :each do
        allow(subject).to receive(:signed_in?) { true }
      end

      it 'should redirect the user away' do
        get :new
        expect(response).to redirect_to('/')
      end

      context 'when return_to is set' do
        it 'should redirect the user to return path' do
          session[:return_to] = '/important_path'
          get :new
          expect(response).to redirect_to('/important_path')
        end
      end
    end
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
