class StackTraceToException < ActiveRecord::Migration
  def up
    rename_column :test_case_runs, :stack_trace, :exception
    execute "UPDATE test_case_runs SET exception = NULL"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
