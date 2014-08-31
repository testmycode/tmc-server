class ExerciseStatusController < ApplicationController

  skip_authorization_check

  def show

    course = params[:course_id]
    participant = params[:id]

    @course = Course.where(name: course).first || Course.where(id: course).first
    @participant = User.where(login: participant).first || User.where(id: participant).first

    respond_access_denied unless @course.visible_to? Guest.new || current_user.administrator?
    results = {}
    @course.exercises.includes(:submissions).where("submissions.user_id = ?", @participant.id).each do |ex|
      status = if ex.completed_by?(@participant)
        'completed'
        elsif ex.attempted_by?(@participant)
          'started'
        else
          'not started'
        end
      results[ex.name] = status
    end

    render json: results
  end


end

