class ProfilesController < ApplicationController
  skip_authorization_check
  
  def show
    if current_user.guest?
      respond_access_denied
    else
      @user = current_user
    end
  end
  
  def update
    @user = current_user
    
    user_params = params[:user]
    @user.email = user_params[:email]
    password_changed = maybe_set_password(@user, user_params)
    
    if @user.errors.empty? && @user.save
      if !@user.password.blank?
        flash[:notice] = 'Changes saved and password changed'
      else
        flash[:notice] = 'Changes saved'
      end
      redirect_to profile_path
    else
      flash.now[:error] = 'Failed to save profile'
      render :action => :show, :status => 403
    end
  end
  
protected
  def maybe_set_password(user, user_params)
    if !user_params[:old_password].blank? || !user_params[:password].blank?
      if !user.has_password?(user_params[:old_password])
        user.errors.add(:old_password, 'incorrect')
      elsif user_params[:password] != user_params[:password_repeat]
        user.errors.add(:password_repeat, 'did not match')
      elsif user_params[:password].blank?
        user.errors.add(:password, 'cannot be empty')
      else
        user.password = user_params[:password]
      end
    end
  end
end