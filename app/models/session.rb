class Session < ActiveRecord::SessionStore::Session
  def self.delete_expired
    self.delete_all(['updated_at < ?', 1.month.ago])
  end

  def belongs_to?(user)
    self.data['user_id'] == user.id
  end
end
