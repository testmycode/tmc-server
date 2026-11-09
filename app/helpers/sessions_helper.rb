# typed: strict
# frozen_string_literal: true

module SessionsHelper
  extend T::Sig
  sig { params(user: User).returns(User) }
  def sign_in(user)
    session[:user_id] = user.id
    @current_user = T.let(user, T.nilable(User))
    user
  end

  sig { returns(User) }
  def current_user
    @current_user ||= T.let(user_from_basic_auth || user_from_session || Guest.new, T.nilable(User))
  end

  sig { params(user: User).void }
  def current_user=(user)
    if user.guest?
      sign_out
    else
      sign_in(user)
    end
  end

  sig { returns(T::Boolean) }
  def signed_in?
    !current_user.guest?
  end

  sig { void }
  def sign_out
    session[:user_id] = nil
    @current_user = Guest.new
    reset_session
  end

  private
    sig { returns(T.nilable(User)) }
    def user_from_session
      User.find_by(id: session[:user_id])
    end

    sig { returns(T.nilable(User)) }
    def user_from_basic_auth
      return unless request && ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)
      username, password = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
      return unless username && password
      user, status = User.authenticate_with_status(username, password)
      PasswordFailureThrottle.record_failure(request) if status == :rejected
      user if status == :accepted
    end
end
