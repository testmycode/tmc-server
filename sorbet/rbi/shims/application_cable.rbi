# typed: true

class ApplicationCable::Connection
  # Defined at runtime by `identified_by :current_user`.
  sig { returns(T.nilable(User)) }
  def current_user; end

  sig { params(current_user: T.nilable(User)).returns(T.nilable(User)) }
  def current_user=(current_user); end
end
