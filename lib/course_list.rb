# Builds /courses.json
class CourseList
  def initialize(user, helpers)
    @user = user
    @helpers = helpers
  end

  def course_list_data(courses)
    courses.map {|c| course_data(c) }
  end

  def course_data(course)
    {
      :id => course.id,
      :name => course.name,
      :details_url => @helpers.course_url(course, :format => :json),
      :unlock_url => @helpers.course_unlock_url(course, :format => :json),
      :reviews_url => @helpers.course_reviews_url(course, :format => :json),
      :comet_url => CometServer.get.client_url,
      :spyware_urls => SiteSetting.value('spyware_servers')
    }
  end
end
