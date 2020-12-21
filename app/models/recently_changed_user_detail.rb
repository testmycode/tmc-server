# frozen_string_literal: true

class RecentlyChangedUserDetail < ApplicationController
  enum change_type: %i[email_changed deleted]
end
