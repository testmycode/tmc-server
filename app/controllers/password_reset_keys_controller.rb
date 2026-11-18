# typed: strict
# frozen_string_literal: true

class PasswordResetKeysController < ApplicationController
  extend T::Sig
  skip_authorization_check

  add_breadcrumb 'Forgot password', ->(*_a) { }, only: %i[new show]

  sig { void }
  def show
    find_key_and_user
  end

  sig { void }
  def new
    redirect_to_courses_mooc_fi
  end

  sig { void }
  def create
    redirect_to_courses_mooc_fi
  end

  sig { void }
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

    user = T.must(@user)
    key = T.must(@key)
    if user.managed_externally?
      success = user.update_password_via_courses_mooc_fi(nil, params[:password])
      if success
        key.destroy
        flash[:success] = 'Your password has been reset.'
        redirect_to root_path
      else
        flash.now[:alert] = 'Failed to reset password.'
        render action: :show, status: :forbidden
      end
    elsif user.externally_managed_without_target?
      # Flagged as managed by courses.mooc.fi but with no id to delegate to. Do not fall back to a
      # local reset (authentication would ignore it); surface the misconfiguration instead.
      Rails.logger.error("Password reset for user #{user.id}: managed by courses.mooc.fi but missing courses_mooc_fi_user_id")
      flash.now[:alert] = 'This account cannot be reset right now. Please contact support.'
      render action: :show, status: :forbidden
    else
      user.password = params[:password]
      if user.save
        # Not yet managed by courses.mooc.fi: migrate the user there with the new password
        user.post_new_user_to_courses_mooc_fi(params[:password])
        key.destroy
        flash[:success] = 'Your password has been reset.'
        redirect_to root_path
      else
        flash.now[:alert] = if user.errors[:password].any?
          'Password ' + user.errors[:password].join(', ')
        else
          'Failed to set password'
        end
        render action: :show, status: :forbidden
      end
    end
  end

  private
    # Only courses.mooc.fi sends password reset mail.
    sig { void }
    def redirect_to_courses_mooc_fi
      reset_url = User.courses_mooc_fi_password_reset_url
      if reset_url
        redirect_to reset_url, allow_other_host: true
      else
        render plain: 'Password reset is unavailable.', status: :service_unavailable
      end
    end

    sig { void }
    def find_key_and_user
      token = params['token']
      key = ActionToken.find_by(token: token)
      @key = T.let(key, T.nilable(ActionToken))
      raise ActiveRecord::RecordNotFound, 'Invalid password reset key' if key.nil? || key.expired?
      @user = T.let(key.user, T.nilable(User))
    end
end
