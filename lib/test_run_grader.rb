require 'point_comparison'

#
# Stores test run results in the database and awards points.
# Called in a transaction from SandboxResultsSaver.
# Expected format of results from sandbox:
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
    raise "Exercise #{submission.exercise_name} was removed" if !submission.exercise

    submission.test_case_runs.destroy_all
    create_test_case_runs(submission, results)

    review_points = submission.exercise.available_points.where(:requires_review => true).map(&:name)
    award_points(submission, results, review_points)
    Unlock.refresh_unlocks(submission.course, submission.user)

    if should_flag_for_review?(submission, review_points)
      submission.requires_review = true
      Submission.where(
        :course_id => submission.course_id,
        :exercise_name => submission.exercise_name,
        :user_id => submission.user.id,
        :requires_review => true
      ).update_all(:requires_review => false)
    end

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

  def self.award_points(submission, results, review_points)
    user = submission.user
    exercise = submission.exercise
    course = exercise.course
    awarded_points = AwardedPoint.course_user_points(course, user).map(&:name)

    points = []
    for point_name in points_from_test_results(results) - review_points
      points << point_name
      unless awarded_points.include?(point_name)
        submission.awarded_points << AwardedPoint.new(
          :name => point_name,
          :course => course,
          :user => user
        )
      end
    end

    old_review_points = submission.points_list.select {|pt| review_points.include?(pt) }
    points += old_review_points

    submission.points = points.uniq.natsort.join(" ") unless points.empty?
  end

  def self.points_from_test_results(results)
    point_status = {}  # point -> true/false/nil i.e. ok so far/failed/unseen
    for result in results
      result['pointNames'].each do |name|
        unless point_status[name].eql?(false) # skip if already failed
          point_status[name] = (result["status"] == 'PASSED')
        end
      end
    end

    point_names = point_status.keys.select {|name| point_status[name] == true }
    PointComparison.sort_point_names(point_names)
  end
  
  def self.to_json_or_null(obj)
    if obj != nil
      ActiveSupport::JSON.encode(obj)
    else
      nil
    end
  end

  def should_flag_for_review?(submission, review_points)
    return false if submission.requests_review
    awarded_points = submission.user.awarded_points.where(:course_id => submission.course.id).map(&:name)
    !(review_points - awarded_points).empty?
  end
end
