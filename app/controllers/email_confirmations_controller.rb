class EmailConfirmationsController < ApplicationController
  skip_authorization_check

  def confirm_email
    token = ActionToken.find_by(token: params[:token])
    user = token.user
    if user
      user.activate_email
      redirect_to root_path, notice: 'Your email has been confirmed. Please sign in to continue.'
    else
      redirect_to root_path, alert:  'Sorry. User does not exist'
    end
  end
end