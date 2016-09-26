class Api::Beta::ParticipantController < Api::Beta::BaseController

  before_action :doorkeeper_authorize!, :scopes => [:public]

  def courses
    user = User.where(id: params[:id]).first || current_user
    authorize! :read, user
    courses = user.courses_with_submissions
    list = CourseList.new(current_user, view_context).course_list_data_no_organisation(Course.find(user.course_ids))
    list.each do |course|
      course[:exercises] = courses[course[:id]]
    end

    present(list)
  end

  def index
    user = current_user
    present({
      username: user.login,
      email: user.email,
    })
  end

end
