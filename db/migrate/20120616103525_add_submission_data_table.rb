class AddSubmissionDataTable < ActiveRecord::Migration
  def up
    create_table :submission_data, :id => false do |t|
      t.integer :submission_id, :null => false
      t.binary :return_file
      t.binary :stdout_compressed
      t.binary :stderr_compressed
    end
    execute 'ALTER TABLE submission_data ADD PRIMARY KEY (submission_id)'
    add_foreign_key :submission_data, :submissions, :dependent => :delete
    execute <<EOS
      INSERT INTO submission_data (submission_id, return_file, stdout_compressed, stderr_compressed)
      SELECT id, return_file, stdout_compressed, stderr_compressed FROM submissions
EOS
    remove_column :submissions, :return_file, :stdout_compressed, :stderr_compressed
  end

  def down
    add_column :submissions, :return_file, :binary
    add_column :submissions, :stdout_compressed, :binary
    add_column :submissions, :stderr_compressed, :binary
    execute <<EOS
      UPDATE submissions
      SET return_file = (SELECT return_file FROM submission_data sd WHERE sd.submission_id = submissions.id),
          stdout_compressed = (SELECT stdout_compressed FROM submission_data sd WHERE sd.submission_id = submissions.id),
          stderr_compressed = (SELECT stderr_compressed FROM submission_data sd WHERE sd.submission_id = submissions.id)
EOS
    drop_table :submission_data
  end
end
