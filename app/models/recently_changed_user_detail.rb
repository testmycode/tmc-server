# frozen_string_literal: true

class RecentlyChangedUserDetail < ApplicationRecord
  enum change_type: %i[email_changed deleted]
end
