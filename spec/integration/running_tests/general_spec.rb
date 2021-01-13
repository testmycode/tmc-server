# frozen_string_literal: true

require 'spec_helper'

describe RemoteSandboxForTesting, type: :request, integration: true do
  include GitTestActions

  def make_setup(exercise_name)
    @setup = SubmissionTestSetup.new(exercise_name: exercise_name)
    @course = @setup.course
    @repo = @setup.repo
    @exercise_project = @setup.exercise_project
    @exercise = @setup.exercise
    @user = @setup.user
    @submission = @setup.submission
  end

  describe 'running tests on a submission for a simple exercise' do
    before :each do
      make_setup 'SimpleExercise'
    end

    it 'should create test results for the submission' do
      skip 'Not working, requires sandbox setup for testing'
      @exercise_project.solve_add
      @setup.make_zip
      RemoteSandboxForTesting.run_submission(@submission)

      expect(@submission).to be_processed

      expect(@submission.test_case_runs).not_to be_empty
      tcr = @submission.test_case_runs.to_a.find { |t| t.test_case_name == 'SimpleTest testAdd' }
      expect(tcr).not_to be_nil
      expect(tcr).to be_successful

      tcr = @submission.test_case_runs.to_a.find { |t| t.test_case_name == 'SimpleTest testSubtract' }
      expect(tcr).not_to be_nil
      expect(tcr).not_to be_successful
    end

    it 'should not create multiple test results for the same test method even if it is involved in multiple points'

    it 'should raise an error if compilation of a test fails' do
      skip 'Not working, requires sandbox setup for testing'
      @exercise_project.introduce_compilation_error
      @setup.make_zip

      RemoteSandboxForTesting.run_submission(@submission)

      expect(@submission.status(@user)).to eq(:error)
      expect(@submission.pretest_error).to match(/Compilation error/)
    end

    it 'should award points for successful exercises' do
      skip 'Not working, requires sandbox setup for testing'
      @exercise_project.solve_sub
      @setup.make_zip
      RemoteSandboxForTesting.run_submission(@submission)

      points = AwardedPoint.where(course_id: @course.id, user_id: @user.id).map(&:name)
      expect(points).to include('justsub')
      expect(points).not_to include('addsub')
      expect(points).not_to include('mul')
      expect(points).not_to include('simpletest-all')
    end

    it "should not award a point if all tests (potentially in multiple files) required for it don't pass" do
      skip 'Not working, requires sandbox setup for testing'
      @exercise_project.solve_addsub
      @setup.make_zip
      RemoteSandboxForTesting.run_submission(@submission)

      points = AwardedPoint.where(course_id: @course.id, user_id: @user.id).map(&:name)
      expect(points).to include('simpletest-all')
      expect(points).not_to include('both-test-files')
    end

    it 'should award a point if all tests (potentially in multiple files) required for it pass' do
      skip 'Not working, requires sandbox setup for testing'
      @exercise_project.solve_all
      @setup.make_zip
      RemoteSandboxForTesting.run_submission(@submission)

      points = AwardedPoint.where(course_id: @course.id, user_id: @user.id).map(&:name)
      expect(points).to include('simpletest-all')
      expect(points).to include('both-test-files')
    end

    it 'should only ever award more points, never delete old points' do
      skip 'Not working, requires sandbox setup for testing'
      @exercise_project.solve_sub
      @setup.make_zip
      RemoteSandboxForTesting.run_submission(@submission)

      @exercise_project.solve_add
      @setup.make_zip
      RemoteSandboxForTesting.run_submission(@submission)

      points = AwardedPoint.where(course_id: @course.id, user_id: @user.id).map(&:name)
      expect(points).to include('justsub')
      expect(points).to include('addsub')
      expect(points).to include('simpletest-all')
      expect(points).not_to include('mul') # in SimpleHiddenTest
    end
  end

  it 'should include tools.jar in the classpath for ant projects' do
    skip 'Not working, requires sandbox setup for testing'
    make_setup 'UsingToolsJar'
    @setup.make_zip
    RemoteSandboxForTesting.run_submission(@submission)
    expect(@submission.status(@user)).to eq(:ok)
  end
end
