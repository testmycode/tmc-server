class Api::V8::ExercisesController < Api::V8::BaseController
  before_action :doorkeeper_authorize!, scopes: [:public]

  def index
    course_id ||= params[:id] || Course.find_by(name: "#{params[:slug]}-#{params[:name]}").id
    present(Exercise.where(course_id: course_id))
  end
end
