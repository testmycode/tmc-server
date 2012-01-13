class EmailsController < ApplicationController
  skip_authorization_check
  
  def index
    return respond_access_denied unless current_user.administrator?
    @emails = User.where(:administrator => false).order(:email).map(&:email)
    respond_to do |format|
      format.text do
        render :text => @emails.join("\n")
      end
    end
  end

end
