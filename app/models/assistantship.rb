class Assistantship < ActiveRecord::Base
  belongs_to :user
  belongs_to :course

  validates :user,
            presence: { message: 'does not exist' },
            uniqueness: { scope: :course, message: 'is already an assistant for this course' }
  validates :course, presence: true
end
