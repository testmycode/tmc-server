# typed: strict
# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    extend T::Sig

    identified_by :current_user

    sig { void }
    def connect
      self.current_user = find_verified_user
    end

    private
      sig { returns(User) }
      def find_verified_user
        User.find_by(id: request.session[:user_id]) || reject_unauthorized_connection
      end
  end
end
