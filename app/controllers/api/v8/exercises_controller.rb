class Api::V8::ExercisesController < Api::V8::BaseController
  before_action :doorkeeper_authorize!, scopes: [:public]

  def index
    present("Org: #{params[:slug]}, Course: #{params[:name]}")
  end
end
