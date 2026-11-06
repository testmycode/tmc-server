# typed: strict
# frozen_string_literal: true

require 'natsort'

# Builds /courses.json
class CourseList
  extend T::Sig

  sig { params(user: User, helpers: ActionView::Base).void }
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  # opts: :include_points and :include_unlock_conditions add those per-course sections.
  sig do
    params(organization: Organization, courses: T::Enumerable[Course], opts: T::Hash[Symbol, T.untyped])
      .returns(T::Array[T::Hash[Symbol, T.untyped]])
  end
  def course_list_data(organization, courses, opts = {})
    courses.map { |c| course_data(organization, c, opts) }
  end

  sig { params(courses: T::Enumerable[Course], opts: T::Hash[Symbol, T.untyped]).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def course_list_data_no_organisation(courses, opts = {})
    courses.map { |c| course_data(T.must(c.organization), c, opts) }
  end

  sig { params(organization: Organization, course: Course, opts: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def course_data(organization, course, opts = {})
    data = T.let({
      id: course.id,
      name: course.name,
      title: course.title,
      details_url: @helpers.organization_course_url(organization, course, format: :json),
      unlock_url: @helpers.organization_course_unlock_url(organization, course, format: :json),
      reviews_url: @helpers.organization_course_reviews_url(organization, course, format: :json),
      comet_url: '',
      spyware_urls: SiteSetting.value('spyware_servers')
    }, T::Hash[Symbol, T.untyped])

    return data unless opts[:include_points] || opts[:include_unlock_conditions]

    exercises = course.exercises.select { |e| e.points_visible_to?(@user) }
    if opts[:include_points]
      sheets = course.gdocs_sheets(exercises).natsort
      data[:points] = {
        sheets: sheets.map do |sheet|
          {
            name: sheet,
            total_available: AvailablePoint.course_sheet_points(course, sheet)[sheet] || 0
          }
        end,
        total_available: AvailablePoint.course_points_of_exercises(course, exercises)
      }
    end

    if opts[:include_unlock_conditions]
      data[:unlock_conditions] = [
        exercises.map do |ex|
          unlock_spec = ex.unlock_spec
          {
            name: ex.name,
            conditions: unlock_spec ? JSON.parse(unlock_spec) : []
          }
        end
      ]
    end

    data
  end
end
