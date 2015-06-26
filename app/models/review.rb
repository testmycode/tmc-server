class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :reviewer, class_name: 'User', inverse_of: :reviews

  def points_list
    points.to_s.split
  end

  def readable_by?(user)
    user.administrator? ||
        user.id == submission.user.id ||
        user.teacher?(submission.course.organization)
  end

  def manageable_by?(user)
    user.administrator? ||
        user.teacher?(submission.course.organization)
  end
end
