class PointsController < ApplicationController
  skip_authorization_check

  def index
    raise CanCan::AccessDenied.new("Access denied to points.", :read, Point) if current_user.guest?
    @course = Course.find(params[:course_id])
    @exercises = @course.exercises
    @users = User.course_students(@course)
  end
end
