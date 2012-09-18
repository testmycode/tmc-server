# Knows who is currently visiting a given page.
class PagePresence < ActiveRecord::Base
  TIMEOUT = 10.seconds     # Records older than this are deleted
  REFRESH_RATE = 5.seconds # Recommended rate of AJAX calls

  belongs_to :user

  def self.visitors_of(path)
    self.where(:path => path).order(:created_at).map(&:user)
  end

  def self.refresh(user, path)
    self.isolation_level(:serializable) do
      self.transaction(:requires_new => true) do
        record = self.where(:user_id => user.id, :path => path).first
        if record
          record.updated_at = Time.now
          record.save!
        else
          self.create!(:user_id => user.id, :path => path)
        end
      end
    end
  rescue ActiveRecord::TransactionIsolationConflict => e
    logger.warn(e.message)
    # Don't care
  end

  def self.delete_older_than_timeout
    self.delete_older_than(TIMEOUT)
  end

  def self.delete_older_than(time)
    self.where(['updated_at < ?', Time.now - time]).delete_all
  end
end
