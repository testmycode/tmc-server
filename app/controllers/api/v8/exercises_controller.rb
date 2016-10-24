class Api::V8::ExercisesController < Api::V8::BaseController
  before_action :doorkeeper_authorize!, scopes: [:public]

  def index
    course_id = params[:id] || Course.find_by(name: "#{params[:slug]}-#{params[:name]}").id
    exercises = Exercise.where(course_id: course_id)
    exs = []
    auth_exs = []
    exercises.each do |ex|
      next unless ex.visible_to?(current_user)
      next if ex.hidden || ex.disabled_status == :disabled
      e = {}
      e[:id] = ex.id
      e[:name] = ex.name
      e[:created_at] = ex.created_at
      e[:updated_at] = ex.updated_at
      e[:publish_time] = ex.publish_time
      e[:solution_visible_after] = ex.solution_visible_after
      e[:deadline] = ex.deadline_for(current_user)
      e[:available_points] = Exercise.find_by(id: ex.id).available_points
      exs.push(e)
      auth_exs.push(ex)
    end
    authorize! :read, auth_exs
    present(exs)
  end
end
