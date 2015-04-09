class Certificate < ActiveRecord::Base
  belongs_to :user
  belongs_to :course

  validates :name, :course, :user, presence: true
  before_save :generate

  def generate
    visible_exercises, available_points = visible_exercises_and_points_for

    data = File.read(File.join(path, 'certificate.html'))
    data %= {
      time: Time.zone.now.to_f * 1000,
      name: name,
      course: course.formal_name,
      weeks: course.exercise_groups.count,
      exercises: visible_exercises.count,
      points: AwardedPoint.course_user_points(course, user).count,
      available_points: available_points.count,
      root: path
    }

    self.pdf = PDFKit.new(data,
                          disable_local_file_access: true,
                          allow: {
                            path => true
                          },
                          page_size: 'A4',
                          orientation: 'Landscape',
                          margin_top: '0.20in',
                          margin_right: '0.20in',
                          margin_bottom: '0.20in',
                          margin_left: '0.20in',
                          image_quality: 100,
                          image_dpi: 300
                         ).to_pdf
  end

  def path
    File.join(course.clone_path, 'certificate')
  end

  private

  def visible_exercises_and_points_for
    visible_exercises = course.exercises.select { |e| e.points_visible_to?(user) }
    total_available = AvailablePoint.course_points_of_exercises(course, visible_exercises)
    [visible_exercises, total_available]
  end
end
