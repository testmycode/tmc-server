require 'gdocs'

class PointsUploadQueue < ActiveRecord::Base
  belongs_to :point

  def self.upload_to_gdocs

    # Get all points that should be uploaded from queueu
    uploads = PointsUploadQueue.all

    # Create a mutex in order to be able to set items to should_be_removed list
    mutex = Mutex.new
    should_be_removed = []
    uploads_errors = {}

    # Initialize empty list, so that spawned threads can be joined later on
    threads = []
    uploads.each do |upload|
      point = Point.find(upload.point_id)
      course_name = ExercisePoint.find(point.exercise_point_id).exercise.course.name
      sheet = point.exercise_point.exercise.gdocs_sheet

      threads << Thread.new(upload, point, course_name, sheet) do |u, p, c, s|
        doc = GDocs.new
        ret_val = upload_point(p, doc, c, s)
        if ret_val[:success]
          mutex.synchronize do
            should_be_removed << u
          end
        else
          mutex.synchronize do
            uploads_errors[:error] = ret_val[:error]
          end
        end
      end
    end

    threads.each { |t| t.join }

    should_be_removed.each { |upload| upload.destroy }

    return uploads_errors
  end

  private

  def self.upload_point point, doc, course_name, sheet
    begin
      doc.add_points_to_student(course_name, point.student_id, sheet, point.exercise_number)
      return {:success => true, :error => nil}
    rescue RuntimeError => e
      case e.to_s
        when "Cell is not empty"
          return {:success => true, :error => nil}
        else
          puts "RuntimeError: " + e.to_s
          return {:success => false, :error => e.to_s}
      end
    end
  end
end
