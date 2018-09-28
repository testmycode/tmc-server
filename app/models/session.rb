# frozen_string_literal: true

class Session < ActiveRecord::SessionStore::Session
  def self.delete_expired
    delete_all(['updated_at < ?', 1.month.ago])
  end

  def belongs_to?(user)
    data['user_id'] == user.id
  end
end
