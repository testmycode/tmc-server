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
      if request&.authorization
        username, password = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
        User.authenticate(username, password) if username && password
      end
    end
end
