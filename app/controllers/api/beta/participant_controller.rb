class Api::Beta::ParticipantController < Api::Beta::BaseController

  before_action :doorkeeper_authorize!, :scopes => [:public]

  def courses
    user = User.where(id: params[:id]).first || current_user
    courses = user.courses
    present(courses)
  end

end
