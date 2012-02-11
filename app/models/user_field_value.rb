class UserFieldValue < ActiveRecord::Base
  include ExtraFieldValue

  belongs_to :user
end
