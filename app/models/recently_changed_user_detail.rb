# frozen_string_literal: true

class RecentlyChangedUserDetail < ActiveRecord::Base
  enum change_type: %i[email_changed deleted]
end
