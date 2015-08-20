require 'spec_helper'

describe EmailConfirmationsController, type: :controller do
  render_views

  before :each do
    @user = User.create!(login: 'test', password: 'foobar', email: 'test@test.com')
  end

  describe 'GET confirm_email' do
    before :each do
      @token = ActionToken.generate_email_confirmation_token(@user)
    end

    it 'with right token should confirm email and destroy token' do
      get :confirm_email, token: @token.token
      @user.reload
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Your email has been confirmed. Please sign in to continue.')
      expect(@user.email_confirmation_token).to be_nil
    end

    it 'with wrong token should flash alert and return rootpage' do
      get :confirm_email, token: @token.token + 'xx'
      @user.reload
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Sorry. User does not exist')
      expect(@user.email_confirmation_token).not_to be_nil
    end
  end

  describe 'GET request_user_to_confirm_email' do
    it 'should give request page for confirming email' do
      session[:non_confirmed_user_id] = @user.id
      get :request_user_to_confirm_email
      expect(response.code.to_i).to eq(200)
      expect(response.body).to have_content('Email confirmation')
    end
  end

  describe 'POST send_email_confirmation' do
    before :each do
      session[:non_confirmed_user_id] = @user.id
    end

    it 'should send confirmation mail and clear session' do
      post :send_confirmation_mail, email: @user.email
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Check your emails and click the confirmation link of the email we send')
      expect(session[:non_confirmed_user_id]).to be_nil
    end

    it 'when email changed should send confirmation mail and change password and clear session' do
      post :send_confirmation_mail, email: 'newmail@test.com'
      @user.reload
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Check your emails and click the confirmation link of the email we send')
      expect(@user.email).to eq('newmail@test.com')
      expect(session[:non_confirmed_user_id]).to be_nil
    end

    it 'when changed email is already taken should direct back and alert user' do
      FactoryGirl.create :user, email: 'taken@test.com'
      user_email = @user.email

      post :send_confirmation_mail, email: 'taken@test.com'
      @user.reload
      expect(response).to redirect_to(email_confirmation_request_path)
      expect(flash[:alert]).to eq('Email address taken@test.com has already been taken by some other user.')
      expect(@user.email).to eq(user_email)
      expect(session[:non_confirmed_user_id]).not_to be_nil
    end
  end
end
