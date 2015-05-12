class Certificate < ActiveRecord::Base
  belongs_to :user
  belongs_to :course

  validates :name, :course, :user, presence: true
  validates :name, uniqueness: {scope: [:user, :course], message: "is already associated with one of your certificates for this course, see My Certificates"}
end
