class PasswordResetKeysController < ApplicationController
  skip_authorization_check

  add_breadcrumb 'Forgot password', lambda {|*a| }, :only => [:new, :show]

  def new
  end

  def create
    @email = params['email'].to_s.strip
    if @email.empty?
      return redirect_to(new_password_reset_key_path, :alert => 'No e-mail address provided')
    end

    user = User.find_by_email(@email)
    if !user
      return redirect_to(new_password_reset_key_path, :alert => 'No such e-mail address registered')
    end

    key = PasswordResetKey.generate_for(user)
    PasswordResetKeyMailer.reset_link_email(user, key).deliver
  end

  def show
    find_key_and_user
  end

  def destroy
    find_key_and_user

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = 'Passwords did not match'
      return render :action => :show, :status => 403
    end

    if params[:password].blank?
      flash.now[:alert] = 'Password may not be empty'
      return render :action => :show, :status => 403
    end

    @user.password = params[:password]
    if @user.save
      @key.destroy
      flash[:success] = 'Your password has been reset.'
      redirect_to root_path
    else
      if @user.errors[:password]
        flash.now[:alert] = 'Password ' + @user.errors[:password].join(', ')
      else
        flash.now[:alert] = 'Failed to set password'
      end
      render :action => :show, :status => 403
    end
  end

private
  def find_key_and_user
    code = params['code']
    @key = PasswordResetKey.find_by_code(code)
    raise ActiveRecord::RecordNotFound.new('Invalid password reset code') if @key.nil? || @key.expired?
    @user = @key.user
  end
end
