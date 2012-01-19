class ParticipantsController < ApplicationController
  skip_authorization_check
  
  def index
    return respond_access_denied unless current_user.administrator?
    @participants = User.where(:administrator => false).order(:login)
    respond_to do |format|
      format.html
      format.json do
        result = []
        @participants.each do |user|
          result << { :id => user.id, :username => user.login, :email => user.email }
        end
        render :json => {
          :api_version => API_VERSION,
          :participants => result
        }
      end
    end
  end
  
  def destroy
    return respond_access_denied unless current_user.administrator?
    
    user = User.find(params[:id])
    user.destroy
    flash[:success] = 'User account deleted'
    redirect_to root_path
  end

end
