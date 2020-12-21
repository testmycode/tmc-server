class AddNeededIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :submissions, :paste_key
    add_index :submissions, [:course_id, :created_at]
    add_index :exercises, :name
    add_index :submissions, :exercise_name
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE INDEX index_user_email_lowercase ON users (lower(email));
        SQL
      end
      dir.down do
        execute <<-SQL
        DROP INDEX index_user_email_lowercase;
        SQL
      end
    end
  end
end
