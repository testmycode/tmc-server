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
end