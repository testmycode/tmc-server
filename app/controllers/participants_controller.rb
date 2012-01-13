class ParticipantsController < ApplicationController
  skip_authorization_check
  
  def index
    return respond_access_denied unless current_user.administrator?
    @participants = User.where(:administrator => false).order(:login)
  end

end
