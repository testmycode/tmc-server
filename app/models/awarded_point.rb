class AwardedPoint < ActiveRecord::Base
  # While these could be computed on the fly from TestCaseRuns,
  # it would require rereading the annotations from the exercise.
  # That would be way too slow, and error-prone too, so we store these.
  # It also makes queries like "points awarded to student X" easier.

  belongs_to :course
  belongs_to :user
end
