class MakeEmailUnique < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DROP INDEX index_user_email_lowercase;
          CREATE UNIQUE INDEX index_user_email_lowercase ON users (lower(email));
        SQL
      end
      dir.down do
        execute <<-SQL
        DROP INDEX index_user_email_lowercase;
        CREATE INDEX index_user_email_lowercase ON users (lower(email));
        SQL
      end
    end
  end
end
