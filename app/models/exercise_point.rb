class ExercisePoint < ActiveRecord::Base
  belongs_to :exercise
  has_many :points, :dependent => :destroy
  #after_create :add_exercise_to_gdocs

  def add_exercise_to_gdocs
    course_name = self.exercise.course.name
    sheet_id = self.exercise.gdocs_sheet.to_s

    account = GDocs.new
    account.add_exercise(course_name, sheet_id, self.point_id)
  end

  def self.extract_exercise_points exercise_path
    exercise_points = []

    point_identifiers = TestRunner.extract_exercise_list exercise_path
    point_identifiers.each do |point_identifier|
      point = ExercisePoint.new
      point.point_id = point_identifier
      exercise_points << point
    end

    return exercise_points
  end

end
