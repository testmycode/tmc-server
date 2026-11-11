# typed: strict
# frozen_string_literal: true

class Session < ActiveRecord::SessionStore::Session
  extend T::Sig

  sig { params(user: User).returns(T::Boolean) }
  def belongs_to?(user)
    T.unsafe(data)['user_id'] == user.id
  end
end
