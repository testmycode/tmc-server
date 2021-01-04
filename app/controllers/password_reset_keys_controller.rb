# frozen_string_literal: true

class PasswordResetKeysController < ApplicationController
  skip_authorization_check

  add_breadcrumb 'Forgot password', ->(*_a) { }, only: %i[new show]

  def new; end

  def create
    @email = params['email'].to_s.strip
    if @email.empty?
      return redirect_to(new_password_reset_key_path, alert: 'No e-mail address provided')
    end

    user = User.find_by('lower(email) = ?', @email.downcase)
    unless user
      return redirect_to(new_password_reset_key_path, alert: 'No such e-mail address registered')
    end

    key = ActionToken.generate_password_reset_key_for(user)
    PasswordResetKeyMailer.reset_link_email(user, key).deliver
  end

  def show
    find_key_and_user
  end

  def destroy
    find_key_and_user

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = 'Passwords did not match'
      return render action: :show, status: :forbidden
    end

    if params[:password].blank?
      flash.now[:alert] = 'Password may not be empty'
      return render action: :show, status: :forbidden
    end

    @user.password = params[:password]
    if @user.save
      @key.destroy
      flash[:success] = 'Your password has been reset.'
      redirect_to root_path
    else
      flash.now[:alert] = if @user.errors[:password]
        'Password ' + @user.errors[:password].join(', ')
      else
        'Failed to set password'
      end
      render action: :show, status: :forbidden
    end
  end

  private

    def find_key_and_user
      token = params['token']
      @key = ActionToken.find_by(token: token)
      raise ActiveRecord::RecordNotFound, 'Invalid password reset key' if @key.nil? || @key.expired?
      @user = @key.user
    end
end
