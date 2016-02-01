# Builds /courses.json
class CourseList
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  def course_list_data(organization, courses)
    courses.map { |c| course_data(organization, c) }
  end

  def course_data(organization, course)
    exercises = course.exercises.select { |e| e.points_visible_to?(@user) }
    sheets = course.gdocs_sheets(exercises).natsort
    {
      id: course.id,
      name: course.name,
      details_url: @helpers.organization_course_url(organization, course, format: :json),
      unlock_url: @helpers.organization_course_unlock_url(organization, course, format: :json),
      reviews_url: @helpers.organization_course_reviews_url(organization, course, format: :json),
      comet_url: CometServer.get.client_url,
      spyware_urls: SiteSetting.value('spyware_servers'),
      sheets: sheets.map do |sheet|
        {
          name: sheet,
          total_available: AvailablePoint.course_sheet_points(course, sheet).length
        }
      end,
      total_available: AvailablePoint.course_points_of_exercises(course, exercises).length,
    }
  end
end
