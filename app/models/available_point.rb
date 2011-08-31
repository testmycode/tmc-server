# Caches points that can be awarded from an exercise.
# Awarded points don't have a hard reference to these because
# these are recreated every time a course is refreshed.
class AvailablePoint < ActiveRecord::Base
  belongs_to :exercise
  has_one :course, :through => :exercise

  # @deprecated
  def self.read_from_project(path)
    TestScanner.get_test_case_methods(path).map{|x| x[:points]}.flatten.uniq
  end
end
