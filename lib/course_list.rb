# Builds /courses.json
class CourseList
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  def course_list_data(organization, courses, opts={})
    courses.map { |c| course_data(organization, c, opts) }
  end

  def course_data(organization, course, opts={})
    @course = course
    data = {
      id: course.id,
      name: course.name,
      details_url: @helpers.organization_course_url(organization, course, format: :json),
      unlock_url: @helpers.organization_course_unlock_url(organization, course, format: :json),
      reviews_url: @helpers.organization_course_reviews_url(organization, course, format: :json),
      comet_url: CometServer.get.client_url,
      spyware_urls: SiteSetting.value('spyware_servers'),
    }

    if opts[:include_points]
      data[:points] = {
        sheets: sheets.map do |sheet|
          {
            name: sheet,
            total_available: AvailablePoint.course_sheet_points(course, sheet)
          }
        end,
        total_available: AvailablePoint.course_points_of_exercises(course, exercises),
      }
    end

    if opts[:include_unlock_conditions]
      data[:unlock_conditions] = [
        exercises.map do |ex|
          {
            name: ex.name,
            conditions: JSON.parse(ex.unlock_spec),
          }
        end
      ]
    end

      data
  end

  private
  def exercises
    @exercises ||= @course.exercises.select { |e| e.points_visible_to?(@user) }
  end

  def sheets
    @sheets ||= @course.gdocs_sheets(exercises).natsort
  end
end
