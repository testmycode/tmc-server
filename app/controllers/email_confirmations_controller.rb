class EmailConfirmationsController < ApplicationController
  skip_authorization_check

  def confirm_email
    token = ActionToken.find_by(token: params[:token], action: 'confirm_email')
    user = token.user if token
    if user
      user.activate_email
      redirect_to root_path, notice: 'Your email has been confirmed. Please sign in to continue.'
    else
      redirect_to root_path, alert:  'Sorry. User does not exist'
    end
  end

  def request_user_to_confirm_email
    @user = user_from_non_confirmed_session
    render 'email_confirmations/email_confirmation_request'
  end

  def send_confirmation_mail
    user = user_from_non_confirmed_session
    return redirect_to root_path unless user
    if user.email != params[:email]
      user.email = params[:email]
      unless user.save
        return redirect_to email_confirmation_request_path, alert: "Email address #{params[:email]} has already been taken by some other user."
      end
    end
    token = ActionToken.generate_email_confirmation_token(user)
    EmailConfirmationMailer.confirmation_link_email(user, token).deliver
    clear_non_confirmed_session_for user
    redirect_to root_path, notice: 'Check your emails and click the confirmation link of the email we send'
  end
end