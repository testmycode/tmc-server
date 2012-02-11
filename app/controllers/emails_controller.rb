class EmailsController < ApplicationController
  skip_authorization_check
  
  def index
    return respond_access_denied unless current_user.administrator?
    filter_params = params_starting_with('filter_', :remove_prefix => true)
    @emails = User.filter_by(filter_params).order(:email).map(&:email)
    respond_to do |format|
      format.text do
        render :text => @emails.join("\n")
      end
    end
  end

end
