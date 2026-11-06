# typed: strict
# frozen_string_literal: true

require 'pdfkit'

class Certificate < ApplicationRecord
  extend T::Sig
  belongs_to :user
  belongs_to :course

  validates :name, :course, :user, presence: true
  before_save :generate

  sig { void }
  def generate
    visible_exercises, available_points = visible_exercises_and_points_for

    data = File.read(File.join(path, 'certificate.html'))
    awarded_points = AwardedPoint.course_user_points(T.must(course), T.must(user)).reject do |p|
      exercise = p.submission.exercise
      exercise.nil? ? false : p.submission.exercise.hide_submission_results?
    end
    data %= {
      time: Time.zone.now.to_f * 1000,
      name: name,
      course: T.must(course).formal_name || T.must(course).title,
      weeks: T.must(course).exercise_groups.count,
      exercises: visible_exercises.count,
      points: awarded_points.count,
      point_names: awarded_points.map(&:name).join(','),
      available_points: available_points,
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
                          image_dpi: 300).to_pdf
  end

  sig { returns(String) }
  def path
    File.join(T.must(course).clone_path, 'certificate')
  end

  private
    sig { returns([T::Array[Exercise], Integer]) }
    def visible_exercises_and_points_for
      visible_exercises = T.must(course).exercises.select { |e| e.points_visible_to?(T.must(user)) }
      total_available = AvailablePoint.course_points_of_exercises(T.must(course), visible_exercises, true)
      [visible_exercises, total_available]
    end
end
