
# Optionally inherited by config/site_tailoring.rb
class Tailoring
  # Must return a string (raw or html-safe) as the title of
  # the given exercise in the /courses/:course_id/points view.
  def exercise_name_for_points_table(exercise)
    exercise.name
  end

  def self.get
    @tailoring ||= begin
      path = "#{::Rails.root}/config/site_tailoring.rb"
      if File.exist?(path)
        require path
        SiteTailoring.new
      else
        Tailoring.new
      end
    end
  end
end

