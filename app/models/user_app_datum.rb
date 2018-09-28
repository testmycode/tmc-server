# frozen_string_literal: true

class UserAppDatum < ActiveRecord::Base
  belongs_to :user
end
