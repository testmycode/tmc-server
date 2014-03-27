class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :reviewer, :class_name => 'User', :inverse_of => :reviews

  def points_list
    points.to_s.split
  end
end
