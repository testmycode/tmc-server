class EmailConfirmationsController < ApplicationController
  skip_authorization_check

  def confirm_email
    user = User.find_by(confirm_token: params[:token])
    if user
      user.email_activate
      redirect_to root_path, notice: 'Your email has been confirmed. Please sign in to continue.'
    else
      redirect_to root_path, alert:  'Sorry. User does not exist'
    end
  end

  def request_user_to_confirm_email
    @user = User.find_by(login: params[:username])
    render 'email_confirmations/email_confirmation_request'
  end

  def send_confirmation_mail
    user = User.find_by(login: params[:username])
    user.generate_confirmation_token
    EmailConfirmationMailer.confirmation_link_email(user).deliver
    redirect_to root_path, notice: 'Check your emails and click the confirmation link of the email we send'
  end
end