class Certificate < ActiveRecord::Base
  belongs_to :user
  belongs_to :course

  validates :name, presence: true
end
