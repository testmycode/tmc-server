# frozen_string_literal: true

# Used to migrate students between similar courses. This requires for the GIT repos to be checkout to same version to ensure safe transition
class StudentSubmissionMigrator
  class CannotRefreshError < RuntimeError; end
  class RefreshFailedError < CannotRefreshError; end
  def initialize(old_course, new_course, user)
    @old_course = old_course
    @new_course = new_course
    @user = user
  end

  def migrate!
    validate_migration!
    ActiveRecord::Base.transaction do
      to_be_migrated = @user.submissions.where(course_id: @old_course.id)

      to_be_migrated.each do |submission|
        migrate_submission_and_data(submission)
      end
      update_app_data
    end
  end

  def migration_is_allowed
    allowed_migrations = SiteSetting.value(:allow_migrations_between_courses)
    return false if allowed_migrations.nil?
    allowed_migrations.each do |allowed_pair|
      puts allowed_pair
      return true if allowed_pair['from'] == @old_course.id && allowed_pair['to'] == @new_course.id
    end
    false
  end

  private

    def validate_migration!
      raise CannotRefreshError, 'Cannot migrate with courses which have diffenent git revisions' unless @old_course.git_revision == @new_course.git_revision
      raise CannotRefreshError, 'Migration between these courses is not allowed' unless migration_is_allowed
    end

    def migrate_submission_and_data(submission)
      new_submission = submission.dup
      new_submission.course = @new_course
      new_submission.save!

      migrate_submission_data(submission, new_submission)
      migrate_test_case_runs(submission, new_submission)
      migrate_awarded_points(submission, new_submission)
      new_submission.save!
      new_submission.reload
      new_submission.update_columns(created_at: submission.created_at, processing_attempts_started_at: submission.processing_attempts_started_at)
      MigratedSubmissions.create!(from_course_id: @old_course.id, to_course_id: @new_course.id, original_submission_id: submission.id, new_submission_id: new_submission.id)
      Unlock.refresh_unlocks(new_submission.course, submission.user)
    end

    def migrate_submission_data(submission, new_submission)
      new_submission_data = submission.submission_data.dup
      new_submission_data.submission = new_submission
      new_submission_data.save!
    end

    def migrate_test_case_runs(submission, new_submission)
      submission.test_case_runs.each do |test_case_run|
        new_test_case_run = test_case_run.dup
        new_test_case_run.submission = new_submission
        new_test_case_run.save!
        new_test_case_run.update_columns(created_at: test_case_run.created_at, updated_at: test_case_run.updated_at)
      end
    end

    def migrate_awarded_points(submission, new_submission)
      submission.awarded_points.each do |awarded_point|
        new_point = awarded_point.dup
        next if AwardedPoint.find_by(course_id: @new_course.id, name: awarded_point.name, user_id: @user.id)
        new_point.course = @new_course
        new_point.submission = new_submission
        new_point.save!
      end
    end

    def update_app_data
      allowed_migrations = SiteSetting.value(:allow_migrations_between_courses)
      return if allowed_migrations.nil?
      migration_entry = allowed_migrations.find do |allowed_pair|
        allowed_pair['from'] == @old_course.id && allowed_pair['to'] == @new_course.id
      end
      return unless migration_entry
      return unless migration_entry['update_app_data']
      app_data_updates = migration_entry['update_app_data']
      app_data_updates.each |adu|
        namespace = adu['namespace']
      set_values.each do |record|
        key = adu['key']
        value = adu['value']
        record = UserAppDatum.find_or_initialize_by(namespace: namespace, key: key)
        record.value = value
        record.save!
      end
    end
end
