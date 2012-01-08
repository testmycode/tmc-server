class UsersController < ApplicationController
  skip_authorization_check
  
  def new
    if signed_in?
      # Logged in from this page. No need to be here, so redirect away
      redirect_to root_path
    else
      @user = User.new
    end
  end
  
  def create
    @user = User.new
    user_params = params[:user]
    
    @user.login = user_params[:login]
    
    if user_params[:email].blank?
      @user.errors.add(:email, 'needed')
    elsif user_params[:email] != user_params[:email_repeat]
      @user.errors.add(:email_repeat, 'did not match')
    else
      @user.email = user_params[:email]
    end
    
    if user_params[:password].blank?
      @user.errors.add(:password, 'needed')
    elsif user_params[:password] != user_params[:password_repeat]
      @user.errors.add(:password_repeat, 'did not match')
    else
      @user.password = user_params[:password]
    end
    
    if @user.errors.empty? && @user.save
      flash[:notice] = 'User account created. You can now log in.'
      redirect_to root_path
    else
      flash.now[:error] = 'Failed'
      render :action => :show, :status => 403
    end
  end
  
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
    password_changed = maybe_update_password(@user, user_params)
    
    if @user.errors.empty? && @user.save
      if !@user.password.blank?
        flash[:notice] = 'Changes saved and password changed'
      else
        flash[:notice] = 'Changes saved'
      end
      redirect_to user_path
    else
      flash.now[:error] = 'Failed to save profile'
      render :action => :show, :status => 403
    end
  end
  
private
  
  def maybe_update_password(user, user_params)
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
      true
    else
      false
    end
  end
end
