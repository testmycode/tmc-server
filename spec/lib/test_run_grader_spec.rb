require 'spec_helper'

describe TestRunGrader do
  include GitTestActions
  # TODO: ad c testcase?
  before :each do
    @submission = Factory.create(:submission, :processed => false)
    ['1.1', '1.2'].each do |name|
      Factory.create(:available_point, :exercise_id => @submission.exercise.id, :name => name)
    end
  end

  def half_successful_results
    [
      {
        'className' => 'MyTest',
        'methodName' => 'testSomethingEasy',
        'status' => 'PASSED',
        'pointNames' => ['1.1', '1.2']
      },
      {
        'className' => 'MyTest',
        'methodName' => 'testSomethingDifficult',
        'status' => 'FAILED',
        'pointNames' => ['1.2'],
        'exception' => {'a' => 'b'}
      }
    ]
  end

  def successful_results
    results = half_successful_results
    results[1]['status'] = 'PASSED'
    results
  end

  it "should create test case runs for the submission" do
    TestRunGrader.grade_results(@submission, half_successful_results)

    @submission.test_case_runs.should_not be_empty
    tcr = @submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'MyTest testSomethingEasy' }
    tcr.should_not be_nil
    tcr.should be_successful
    tcr.exception.should be_nil

    tcr = @submission.test_case_runs.to_a.find {|tcr| tcr.test_case_name == 'MyTest testSomethingDifficult' }
    tcr.should_not be_nil
    tcr.should_not be_successful
    ActiveSupport::JSON.decode(tcr.exception).should == {'a' => 'b'}
  end

  it "should not create multiple test case runs for the same test method even if it is involved in multiple points" do
    results = [
      {
        'className' => 'MyTest',
        'methodName' => 'testSomething',
        'status' => 'PASSED',
        'pointNames' => ['1.1', '1.2']
      }
    ]

    TestRunGrader.grade_results(@submission, results)

    @submission.test_case_runs.count.should == 1
  end

  it "should award points for which all required tests passed" do
    TestRunGrader.grade_results(@submission, half_successful_results)

    points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
    points.should include('1.1')
    points.should_not include('1.2')

    # Should not depend on result order, so let's try the same in reverse order

    @submission = Factory.create(:submission, :processed => false)
    TestRunGrader.grade_results(@submission, half_successful_results.reverse)

    points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
    points.should include('1.1')
    points.should_not include('1.2')
  end

  it "should always mark awarded points in the submission record but not create duplicate awarded_points rows" do
    TestRunGrader.grade_results(@submission, half_successful_results)

    points = @submission.awarded_points.map(&:name)
    points.should include('1.1')
    points.should_not include('1.2')
    @submission.points.should == '1.1'


    @submission = Factory.create(:submission, {
      :course => @submission.course,
      :exercise => @submission.exercise,
      :user => @submission.user,
      :processed => false
    })
    TestRunGrader.grade_results(@submission, successful_results)

    points = @submission.awarded_points.map(&:name)
    points.should_not include('1.1')
    points.should include('1.2')
    @submission.points.should == '1.1 1.2'
  end

  it "should only ever award more points, never delete old points" do
    results = [
      {
        'className' => 'MyTest',
        'methodName' => 'one',
        'status' => 'PASSED',
        'pointNames' => ['1.1']
      },
      {
        'className' => 'MyTest',
        'methodName' => 'two',
        'status' => 'FAILED',
        'pointNames' => ['1.2']
      }
    ]

    TestRunGrader.grade_results(@submission, results)

    results[0]['status'] = 'FAILED'
    results[1]['status'] = 'PASSED'

    @submission = Submission.new(
      :user => @submission.user,
      :course => @submission.course,
      :exercise => @submission.exercise
    )

    TestRunGrader.grade_results(@submission, results)

    points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
    points.should include('1.1')
    points.should include('1.2')
  end

  it "should work when the exercise has changed name after acquiring points (bug #84)" do
    user = @submission.user
    exercise = @submission.exercise
    course = exercise.course

    TestRunGrader.grade_results(@submission, half_successful_results)
    exercise.update_attribute(:name, 'another_name')
    new_submission = Factory.create(:submission, :user => user, :exercise_name => exercise.name, :course => course, :processed => false)
    TestRunGrader.grade_results(new_submission, successful_results)

    points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
    points.should include('1.1')
    points.should include('1.2')
  end

  describe "when validation errors strategy is fail" do

    def failing_validations
      {
        "strategy" => "fail",
        "validationErrors" =>
        {
          "SimpleStuff.java" =>
          [
            {
              "column" => 40,
              "line" => 6,
              "message" => "'{' is not preceded with whitespace.",
              "sourceName" =>
              "com.puppycrawl.tools.checkstyle.checks.whitespace.WhitespaceAroundCheck"
            },
            {
              "column" => 0,
              "line" => 12,
              "message" => "Indentation incorrect. Expected 8, but was 4.",
              "sourceName "=>
              "com.puppycrawl.tools.checkstyle.checks.indentation.IndentationCheck"
            },
            {
              "column" => 0,
              "line" => 17,
              "message" => "Indentation incorrect. Expected 8, but was 7.",
              "sourceName" =>
              "com.puppycrawl.tools.checkstyle.checks.indentation.IndentationCheck"
            }
          ]
        }
      }
    end

    def no_failures_in_validations
      result = failing_validations
      result['validationErrors'] = []
      result
    end

    def failures_but_no_fail
      result = failing_validations
      result['strategy'] = 'none'
      result
    end


    it "should not award points for which all required tests passed but validations are failed and strategy is 'fail'" do
      @submission.validations = failing_validations.to_json.to_s
      TestRunGrader.grade_results(@submission, half_successful_results)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should_not include('1.1')
      points.should_not include('1.2')

      # Should not depend on result order, so let's try the same in reverse order

      @submission = Factory.create(:submission, :processed => false)
      @submission.validations = failing_validations.to_json.to_s
      TestRunGrader.grade_results(@submission, half_successful_results.reverse)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should_not include('1.1')
      points.should_not include('1.2')
    end

    it "should  award points for which all required tests passed and no validations are failed and strategy is 'fail'" do
      @submission.validations = no_failures_in_validations.to_json.to_s
      TestRunGrader.grade_results(@submission, half_successful_results)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should include('1.1')
      points.should_not include('1.2')

      # Should not depend on result order, so let's try the same in reverse order

      @submission = Factory.create(:submission, :processed => false)
      @submission.validations = no_failures_in_validations.to_json.to_s
      TestRunGrader.grade_results(@submission, half_successful_results.reverse)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should include('1.1')
      points.should_not include('1.2')
    end

    it "should award points for which all required tests passed but validations are failed and strategy is not 'fail'" do
      @submission.validations = failures_but_no_fail.to_json.to_s
      TestRunGrader.grade_results(@submission, half_successful_results)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should include('1.1')
      points.should_not include('1.2')

      # Should not depend on result order, so let's try the same in reverse order

      @submission = Factory.create(:submission, :processed => false)
      @submission.validations = failures_but_no_fail.to_json.to_s
      TestRunGrader.grade_results(@submission, half_successful_results.reverse)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should include('1.1')
      points.should_not include('1.2')
    end

  end

  describe "when the exercise requires code review" do
    before :each do
      ap = AvailablePoint.find_by_name('1.1')
      ap.requires_review = true
      ap.save!
    end

    it "should not award points that require review" do
      TestRunGrader.grade_results(@submission, successful_results)

      points = AwardedPoint.where(:course_id => @submission.course_id, :user_id => @submission.user_id).map(&:name)
      points.should_not include('1.1')
      points.should include('1.2')
    end

    it "should preserve old review points" do
      AwardedPoint.create!(:course_id => @submission.course_id, :user_id => @submission.user_id, :name => '1.1')
      @submission.points = '1.1'
      TestRunGrader.grade_results(@submission, successful_results)
      @submission.points_list.should include('1.1')
    end

    it "should flag the submission as requiring review if the exercise has review points" do
      TestRunGrader.grade_results(@submission, successful_results)

      @submission.should require_review
    end

    it "should unflag all previous submissions to the same exercise" do
      old_sub = Submission.create!(
        :user => @submission.user,
        :course => @submission.course,
        :exercise => @submission.exercise,
        :requires_review => true
      )

      other_exercise_sub = Submission.create!(
        :user => @submission.user,
        :course => @submission.course,
        :exercise => Factory.create(:exercise, :course => @submission.course),
        :requires_review => true
      )
      other_user_sub = Submission.create!(
        :user => Factory.create(:user),
        :course => @submission.course,
        :exercise => @submission.exercise,
        :requires_review => true
      )

      TestRunGrader.grade_results(@submission, successful_results)
      [old_sub, other_exercise_sub, other_user_sub].each(&:reload)

      old_sub.should_not require_review

      other_exercise_sub.should require_review
      other_user_sub.should require_review
    end

    it "should not flag the submission as requiring review if the user has already scored the review points" do
      AwardedPoint.create(:course => @submission.course, :user => @submission.user, :name => '1.1')

      TestRunGrader.grade_results(@submission, successful_results)

      @submission.should_not require_review
    end

    it "should not flag the submission as requiring review if the submission requests review" do
      @submission.requests_review = true

      TestRunGrader.grade_results(@submission, successful_results)

      @submission.should_not require_review
    end
  end
end
