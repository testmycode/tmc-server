
#
# Stores test run results in the database.
# Called in a transaction from SandboxResultsSaver.
# Expected format of results:
#   An array of hashes with the following keys:
#     - className: the test class name
#     - methodName: the test method name
#     - message: error message, if any
#     - status: 'PASSED' or some other string
#     - pointNames: array of point names that require this test to pass
#     - stackTrace: a stack trace structure, if any
#
module TestRunGrader
  extend TestRunGrader
  
  def grade_results(submission, results)
    submission.test_case_runs.destroy_all
    create_test_case_runs(submission, results)
    award_points(submission, results)
    submission.save!
  end
  
private
  def self.create_test_case_runs(submission, results)
    all_passed = true
    results.each do |test_result|
      passed = test_result["status"] == 'PASSED'
      tcr = TestCaseRun.new(
        :test_case_name => "#{test_result['className']} #{test_result['methodName']}",
        :message => test_result["message"],
        :successful => passed,
        :exception => to_json_or_null(test_result["exception"])
      )
      all_passed = false if not passed
      submission.test_case_runs << tcr
    end
    submission.all_tests_passed = all_passed
  end

  def self.award_points(submission, results)
    user = submission.user
    exercise = submission.exercise
    course = exercise.course
    awarded_points = AwardedPoint.exercise_user_points(exercise, user)

    for point_name in points_from_test_results(results)
      if awarded_points.where(:name => point_name).empty?
        submission.awarded_points << AwardedPoint.new(
          :name => point_name,
          :course => course,
          :user => user
        )
      end
    end
  end

  def self.points_from_test_results(results)
    results.reduce({}) do |points, result|
      result["pointNames"].each do |name|
        unless points[name] == false
          points[name] = (result["status"] == 'PASSED')
        end
      end
      points
    end.reduce([]) do |point_names, (name, success)|
      point_names << name if success
      point_names
    end
  end
  
  def self.to_json_or_null(obj)
    if obj != nil
      ActiveSupport::JSON.encode(obj)
    else
      nil
    end
  end
end
