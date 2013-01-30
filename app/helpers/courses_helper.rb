module CoursesHelper
  def response_body_for(body, language="fi")
    return "kirjoitit:\n\n#{body}\n\n---\n\n" if language=="fi"
    return "#{body}"
  end
end