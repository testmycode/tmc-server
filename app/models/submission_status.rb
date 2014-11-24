class SubmissionStatus < ActiveRecord::Base
  attr_accessible :number, :value

  has_many :submissions
end
