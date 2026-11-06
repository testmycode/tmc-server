# typed: strict
# frozen_string_literal: true

class RecentlyChangedUserDetail < ApplicationRecord
  enum :change_type, { email_changed: 0, deleted: 1 }
end
