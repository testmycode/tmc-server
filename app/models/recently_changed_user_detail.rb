class RecentlyChangedUserDetail < ActiveRecord::Base
  enum change_type: [:email_changed, :deleted]
end
