# typed: strict
# frozen_string_literal: true

require 'course_list'

class Api::Beta::ParticipantController < Api::Beta::BaseController
  extend T::Sig

  before_action :doorkeeper_authorize!, scopes: [:public]

  sig { void }
  def courses
    user = User.where(id: params[:id]).first || current_user
    authorize! :read, user
    courses = user.courses_with_submissions
    list = CourseList.new(current_user, view_context).course_list_data_no_organisation(Course.find(T.let(user.course_ids, T::Array[Numeric])))
    list.each do |course|
      course[:exercises] = courses[course[:id]]
    end

    present(list)
  end

  sig { void }
  def index
    user = current_user
    present(username: user.login,
            email: user.email,
            id: user.id)
  end
end
