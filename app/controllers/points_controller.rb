class PointsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    @exercises = @course.exercises
    @users = User.course_students(@course)
  end
end
