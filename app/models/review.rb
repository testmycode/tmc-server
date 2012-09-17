class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :reviewer, :class_name => 'User', :inverse_of => :reviews
end