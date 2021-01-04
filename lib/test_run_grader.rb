# frozen_string_literal: true

require 'point_comparison'
require 'natsort'

# Stores test run results in the database and awards points.
# Called in a transaction from SandboxResultsSaver.
# Expected format of results from sandbox:
#   An array of hashes with the following keys:
#     - className: the test class name
#     - methodName: the test method name
#     - message: error message, if any
#     - status: 'PASSED' or some other string
#     - pointNames: array of point names that require this test to pass
#     - exception: nil, or the following structure:
#       - className: the exception's class
#       - message: the exception's message.
#       - stackTrace: an array of the following structure:
#         - declaringClass
#         - methodName
#         - fileName (may be nil)
#         - lineNumber: (-1 if not available)
#       - cause: the same exception structure again, or nil
#
module TestRunGrader
  extend TestRunGrader

  def grade_results(submission, results)
    raise "Exercise #{submission.exercise_name} was removed" unless submission.exercise

    submission.test_case_runs.destroy_all
    create_test_case_runs(submission, results)

    review_points = submission.exercise.available_points.where(requires_review: true).map(&:name)
    award_points(submission, results, review_points)
    UncomputedUnlock.create!(course: submission.course, user: submission.user)
    # Unlock.refresh_unlocks(submission.course, submission.user)

    if should_flag_for_review?(submission, review_points)
      submission.requires_review = true
      Submission.where(
        course_id: submission.course_id,
        exercise_name: submission.exercise_name,
        user_id: submission.user.id,
        requires_review: true
      ).update_all(requires_review: false)
    end

    submission.save!
  end

  private
    def self.create_test_case_runs(submission, results)
      all_passed = true
      results['testResults'].each do |test_result|
        passed = test_result['successful']
        tcr = TestCaseRun.new(
          test_case_name: test_result['name'],
          message: test_result['message'],
          successful: passed,
          exception: to_json_or_null(test_result['exception']),
          detailed_message: test_result['detailed_message'] || test_result['valgrindTrace'] || test_result['backtrace']
        )
        all_passed = false unless passed
        submission.test_case_runs << tcr
      end
      submission.all_tests_passed = all_passed && validations_passed?(submission.validations) && valgrind_passed?(submission)
    end

    def validations_passed?(validations)
      if !validations.nil? && validations['strategy'] && validations['strategy'] == 'FAIL'
        return false if validations['validationErrors']&.any?
      end
      true
    end

    def valgrind_passed?(submission)
      if submission.exercise.valgrind_strategy == 'fail'
        submission.valgrind.blank?
      else
        true
      end
    end

    def self.award_points(submission, results, review_points)
      user = submission.user
      exercise = submission.exercise
      course = exercise.course
      available_points = exercise.available_points.to_a.map(&:name)
      awarded_points = AwardedPoint.course_user_points(course, user).map(&:name)
      soft_deadline = exercise.soft_deadline_for(user)
      awarded_after_soft_deadline = false
      awarded_after_soft_deadline = true if soft_deadline && Exercise.deadline_expired?(soft_deadline, submission.created_at)

      points = []
      ((available_points & points_from_test_results(results)) - review_points).each do |point_name|
        next unless validations_passed?(submission.validations) && valgrind_passed?(submission)
        points << point_name
        next if awarded_points.include?(point_name)
        submission.awarded_points << AwardedPoint.new(
          name: point_name,
          course: course,
          user: user,
          awarded_after_soft_deadline: awarded_after_soft_deadline
        )
      end

      old_review_points = submission.points_list.select { |pt| review_points.include?(pt) }
      points += old_review_points

      submission.points = points.uniq.natsort.join(' ') unless points.empty?
    end

    def self.points_from_test_results(results)
      point_status = {} # point -> true / false / nil i.e. ok so far / failed / unseen
      results['testResults'].each do |result|
        result['points'].each do |name|
          unless point_status[name].eql?(false) # skip if already failed
            point_status[name] = result['successful']
          end
        end
      end

      point_names = point_status.keys.select { |name| point_status[name] == true }
      PointComparison.sort_point_names(point_names)
    end

    def self.to_json_or_null(obj)
      ActiveSupport::JSON.encode(obj) unless obj.nil?
    end

    def should_flag_for_review?(submission, review_points)
      return false if submission.requests_review
      awarded_points = submission.user.awarded_points.where(course_id: submission.course.id).map(&:name)
      !(review_points - awarded_points).empty?
    end
end
