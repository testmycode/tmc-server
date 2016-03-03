require 'spec_helper'
require 'student_submission_migrator'

describe StudentSubmissionMigrator  do
    before :each do
      @course = FactoryGirl.create(:course)
      allow(@course).to receive(:git_revision) {"same"}
      @other_course = @course.dup
      @other_course.name = @other_course.name + "1"
      @other_course.save!
      allow(@other_course).to receive(:git_revision) {"same"}

      @user = FactoryGirl.create(:user)

      @sheet1 = 'sheet1'
      @sheet2 = 'sheet2'

      @ex1 = FactoryGirl.create(:exercise, course: @course,
                                           gdocs_sheet: @sheet1)
      @ex2 = FactoryGirl.create(:exercise, course: @course,
                                           gdocs_sheet: @sheet2)

      @sub1 = FactoryGirl.create(:submission, course: @course,
                                              user: @user,
                                              exercise: @ex1)
      @sub2 = FactoryGirl.create(:submission, course: @course,
                                              user: @user,
                                              exercise: @ex2)

      @sub1.submission_data = FactoryGirl.create(:submission_data, submission: @sub1)
      @sub2.submission_data = FactoryGirl.create(:submission_data, submission: @sub2)

      FactoryGirl.create(:available_point, exercise: @ex1, name: 'ap')
      FactoryGirl.create(:available_point, exercise: @ex2, name: 'ap2')

      @ap = FactoryGirl.create(:awarded_point, course: @course,
                                               user: @user, name: 'ap',
                                               submission: @sub1)
      @ap2 = FactoryGirl.create(:awarded_point, course: @course,
                                                user: @user, name: 'ap2',
                                                submission: @sub2)
      allow(SiteSetting).to receive(:value).and_return([{'from' => @course.id, 'to' => @other_course.id}])
    end
  it 'copies over stuff' do
    expect(@user.submissions.where(course: @other_course)).to be_empty
    sleep(10)
    migrator = StudentSubmissionMigrator.new(@course, @other_course, @user)
    migrator.migrate!
    expect(@user.submissions.where(course: @other_course)).not_to be_empty

    expect_submission_existence(@user.submissions.find_by(course: @other_course, exercise_name: @ex1.name), @sub1)
    expect_submission_existence(@user.submissions.find_by(course: @other_course, exercise_name: @ex2.name), @sub2)

    expect_awarded_points(@user.awarded_points.find_by(course: @other_course, name: 'ap'), @user.awarded_points.find_by(course: @course, name: 'ap'))
    expect_awarded_points(@user.awarded_points.find_by(course: @other_course, name: 'ap2'), @user.awarded_points.find_by(course: @course, name: 'ap2'))

    expect(MigratedSubmissions.find_by(to_course_id: @other_course.id, original_submission_id: @sub1)).not_to be_nil
    expect(MigratedSubmissions.find_by(to_course_id: @other_course.id, original_submission_id: @sub2)).not_to be_nil
  end

  it 'throws exception if it cannot be migrated safely' do
    bad_course = FactoryGirl.create(:course)
    allow(bad_course).to receive(:git_revision) {"other"}
    migrator = StudentSubmissionMigrator.new(@course, bad_course, @user)
    expect {migrator.migrate!}.to raise_exception(StudentSubmissionMigrator::CannotRefreshError)
  end

  def expect_submission_existence(new_submission, old_submission)
    s1 = new_submission.attributes
    s2 = old_submission.attributes
    %w{course_id id secret_token created_at updated_at processing_attempts_started_at}.each do |field|
      s1.delete(field)
      s2.delete(field)
    end
    expect(s1).to eql(s2)
    s1 = new_submission.attributes
    s2 = old_submission.attributes
    %w{created_at updated_at processing_attempts_started_at}.each do |field|
      expect(s1[field] - s2[field]).to be < 0.001 # for minor inconsistencies with timestamps accuracy...
    end

    expect_submission_data_correctness(new_submission.submission_data, old_submission.submission_data)
  end

  def expect_submission_data_correctness(new_submission_data, old_submission_data)
    s1 = new_submission_data.attributes
    s2 = old_submission_data.attributes
    %w{course_id submission_id id return_file}.each do |field|
      s1.delete(field)
      s2.delete(field)
    end
    expect(s1).to eq(s2)
  end
  def expect_awarded_points(new_awarded_points, old_awarded_points)
    s1 = new_awarded_points.attributes
    s2 = old_awarded_points.attributes
    %w{course_id submission_id id}.each do |field|
      s1.delete(field)
      s2.delete(field)
    end
    expect(s1).to eq(s2)

  end

end

