class AddAllTestsSuccessfulToSubmissions < ActiveRecord::Migration
  def up
    add_column :submissions, :all_tests_passed, :boolean, null: false, default: false
    execute <<SQL
UPDATE submissions sub
SET all_tests_passed =
  processed AND
  pretest_error IS NULL AND
  NOT EXISTS
    (SELECT 1 FROM test_case_runs tcr WHERE tcr.submission_id = sub.id AND successful = false)
SQL
  end

  def down
    remove_column :submissions, :all_tests_passed
  end
end
