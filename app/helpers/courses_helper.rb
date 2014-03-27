module CoursesHelper
  def response_body_for(body)
    return "You wrote:\n\n#{body}\n\n---\n\n"
    return "#{body}"
  end
end
