class Point < ActiveRecord::Base
  belongs_to :exercise
  has_one :course, :through => :exercise

  has_many :awarded_points, :dependent => :destroy

  scope :course_points, lambda { |course|
    joins(:course).where(:courses => {:id => course.id})
  }

  scope :user_points, lambda { |user|
    joins(:awarded_points).where(:awarded_points => {:user_id => user.id})
  }

  scope :course_user_points, lambda { |course, user|
    course_points(course).user_points(user)
  }

  def self.read_point_names path
    TmcJavalib.get_test_case_methods(path).map{|x| x[:points]}.flatten.uniq
  end
end
