class Point < ActiveRecord::Base
  belongs_to :exercise
  has_many :awarded_points
end
