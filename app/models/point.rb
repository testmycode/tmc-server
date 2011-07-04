class Point < ActiveRecord::Base
  belongs_to :course
  has_many :points_upload_queues, :dependent => :destroy
  belongs_to :exercise_point

  validates :exercise_point_id, :presence => true
 
  def self.separate_succ_and_fail test_suite_run
    test_case_runs = test_suite_run.test_case_runs

    exercise_success = {}
    exercise_fail = {}
    test_case_runs.each do |t|
      exercise_success[t.exercise] ||= t
      exercise_fail[t.exercise] ||= false
      if not t.success
        exercise_success[t.exercise] = false
        exercise_fail[t.exercise] = t
      end
    end
    return [exercise_success, exercise_fail]
  end

  def self.check_points test_suite_run
    success_fail_tests_list = separate_succ_and_fail test_suite_run

    exercise_success = success_fail_tests_list[0]
    exercise_fail = success_fail_tests_list[1]

    puts "Exercise success: " + exercise_success.inspect
    puts "Exercise fail: " + exercise_fail.inspect
    exercise_success.each do |key, run|

      if exercise_success[key]
        ep = ExercisePoint.where(
          :exercise_id => test_suite_run.exercise_return.exercise.id,
          :point_id => run.exercise).first

        created_point = Point.create!(:exercise_number => run.exercise,
          :student_id => test_suite_run.exercise_return.student_id,
          :exercise_point_id => ep.id,
          :tests_pass => true)

        PointsUploadQueue.create! :point_id => created_point.id
      else
        ep = ExercisePoint.where(
          :exercise_id => test_suite_run.exercise_return.exercise.id,
          :point_id => exercise_fail[key].exercise).first

        Point.create!(:exercise_number => exercise_fail[key].exercise,
          :student_id => test_suite_run.exercise_return.student_id,
          :exercise_point_id => ep.id,
          :tests_pass => false)
      end
    end
  end
end
