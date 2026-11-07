# typed: strict
# frozen_string_literal: true

# Optionally inherited by config/site_tailoring.rb
class Tailoring
  extend T::Sig
  # If false, only show bare point names in points table
  sig { returns(T::Boolean) }
  def show_exercise_names_in_points_table
    true
  end

  # Must return a string (raw or html-safe) as the title of
  # the given exercise in the /courses/:course_id/points view.
  sig { params(exercise: Exercise).returns(T.nilable(String)) }
  def exercise_name_for_points_table(exercise)
    exercise.name
  end

  sig { returns(Tailoring) }
  def self.get
    @tailoring ||= T.let(begin
      path = Rails.root.join('config/site_tailoring.rb').to_s
      if File.exist?(path)
        require path
        SiteTailoring.new
      else
        Tailoring.new
      end
    end, T.nilable(Tailoring))
  end
end
