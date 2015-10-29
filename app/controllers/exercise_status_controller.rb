class ExerciseStatusController < ApplicationController
  skip_authorization_check

  def show
    course_name = params[:course_name]
    user_id = params[:id]

    course = Course.where(id: course_name).first || Course.where(name: course_name).first
    user = User.where(id: user_id).first || User.where(login: user_id).first

    return respond_access_denied unless course.visible_to?(Guest.new) || current_user.administrator?

    user_subs = user.submissions.where(course_id: course.id).to_a.group_by(&:exercise_name)
    user_subs.default = []

    results = {}
    course.exercises.each do |ex|
      ex.set_submissions_by(user, user_subs[ex.name]) # used by completed_by? and attempted_by?
      if ex.completed_by?(user)
        results[ex.name] = 'completed'
      elsif ex.attempted_by?(user)
        results[ex.name] = 'attempted'
      else
        results[ex.name] = 'not_attempted'
      end
    end

    respond_to do |format|
      format.json do
        render json: results
      end
      format.html do
        respond_not_found('Please add .json to the URL')
      end
    end
  end
end
