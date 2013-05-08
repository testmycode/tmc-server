class CourseNotification < ActiveRecord::Base
  attr_accessor :topic, :message, :user, :course
  belongs_to :course
  belongs_to :user
end
