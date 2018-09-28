# frozen_string_literal: true

module CoursesHelper
  def response_body_for(body)
    return "You wrote:\n\n#{body}\n\n---\n\n"
    body.to_s
  end
end
