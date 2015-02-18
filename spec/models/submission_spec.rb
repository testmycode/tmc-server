# encoding: utf-8

# -*- coding: UTF-8 -*-

require 'spec_helper'

describe Submission, type: :model do
  describe 'validation' do
    before :each do
      @params = {
        course: mock_model(Course),
        exercise_name: 'MyExerciseThatDoesntNecessarilyExist',
        user: mock_model(User)
      }
    end

    it 'should succeed given valid parameters' do
      expect(Submission.new(@params)).to be_valid
    end

    it 'should require a user' do
      @params.delete :user

      submission = Submission.new(@params)
      expect(submission).not_to be_valid
      expect(submission.errors[:user].size).to eq(1)
    end

    it 'should require an exercise name' do
      @params.delete :exercise_name

      submission = Submission.new(@params)
      expect(submission).not_to be_valid
      expect(submission.errors[:exercise_name].size).to eq(1)
    end

    it 'should take exercise name from given exercise object' do
      @params.delete :exercise_name
      @params[:exercise] = mock_model(Exercise, name: 'MyExercise123')
      sub = Submission.new(@params)
      expect(sub).to be_valid
      expect(sub.exercise_name).to eq('MyExercise123')
    end

    it 'should require a course' do
      @params.delete :course

      submission = Submission.new(@params)
      expect(submission).not_to be_valid
      expect(submission.errors[:course].size).to eq(1)
    end
  end

  it 'can summarize test cases' do
    submission = Submission.new
    submission.test_case_runs << TestCaseRun.new(test_case_name: 'Moo moo()', message: 'you fail', successful: false, exception: '{"a": "b"}')
    submission.test_case_runs << TestCaseRun.new(test_case_name: 'Moo moo2()', successful: true)
    submission.test_case_runs << TestCaseRun.new(test_case_name: 'Moo moo()', message: 'you fail', successful: false, detailed_message: 'trace')
    expect(submission.test_case_records).to eq([
      {
        name: 'Moo moo()',
        successful: false,
        message: 'you fail',
        exception: { 'a' => 'b' },
        detailed_message: nil
      },
      {
        name: 'Moo moo2()',
        successful: true,
        message: nil,
        exception: nil,
        detailed_message: nil
      },
      {
        name: 'Moo moo()',
        successful: false,
        message: 'you fail',
        exception: nil,
        detailed_message: 'trace'
      }
    ])
  end

  it 'can tell how many unprocessed submissions are in queue before itself' do
    t = Time.now
    FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 10.seconds)
    FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 9.seconds)
    FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 8.seconds, processing_priority: -2)
    FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 7.seconds)
    s = FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 6.seconds)
    FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 5.seconds)
    FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 4.seconds)

    expect(s.unprocessed_submissions_before_this).to eq(3)
  end

  it 'orders unprocessed submissions by priority, then by last processing attempt time' do
    t = Time.now
    s1 = FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 7.seconds)
    s2 = FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 8.seconds)
    s3 = FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 9.seconds, processing_priority: 1)
    s4 = FactoryGirl.create(:submission, processed: false, processing_tried_at: t - 10.seconds)

    expected_order = [s3, s4, s2, s1]

    expect(Submission.to_be_reprocessed.map(&:id)).to eq(expected_order.map(&:id))
  end

  it 'stores stdout and stderr compressed' do
    s = FactoryGirl.create(:submission)
    s.stdout = 'hello'
    expect(s.submission_data.stdout_compressed).not_to be_empty
    s.stderr = 'world'
    expect(s.submission_data.stderr_compressed).not_to be_empty
    s.save!

    s = Submission.find(s.id)
    expect(s.stdout).to eq('hello')
    expect(s.stderr).to eq('world')
  end

  it 'can have null stdout and stderr' do
    s = FactoryGirl.create(:submission)
    s.stdout = 'hello'
    s.stderr = 'world'
    s.stdout = nil
    expect(s.stdout).to be_nil
    expect(s.submission_data.stdout_compressed).to be_nil
    s.stderr = nil
    expect(s.stderr).to be_nil
    expect(s.submission_data.stderr_compressed).to be_nil
    s.save!
  end

  it 'allows utf-8 caharacters in stdout, stderr and vm_log' do
    s = FactoryGirl.create(:submission)
    s.stdout = 'mää'
    s.stderr = 'möö'
    s.vm_log = 'måå'
    s.valgrind = 'måå'
    s.save!

    s = Submission.find(s.id)
    expect(s.stdout).to eq('mää')
    expect(s.stderr).to eq('möö')
    expect(s.vm_log).to eq('måå')
    expect(s.valgrind).to eq('måå')
  end

  it 'deletes submission data when destroyed' do
    s = FactoryGirl.create(:submission)
    s.stdout = 'hello'
    s.save!

    id = s.id
    s.destroy
    expect(SubmissionData.find_by_submission_id(id)).to be_nil
  end
end
