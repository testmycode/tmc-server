class AwardedPoint < ActiveRecord::Base
  belongs_to :course
  belongs_to :user
  belongs_to :submission

  validates_uniqueness_of :name, :scope => [:user_id, :course_id]
end
