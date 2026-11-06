# typed: strict
# frozen_string_literal: true

module CoursesHelper
  extend T::Sig
  sig { params(body: T.untyped).returns(String) }
  def response_body_for(body)
    "You wrote:\n\n#{body}\n\n---\n\n"
  end
end
