class AddCompressedStdoutAndStderrToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :stdout_compressed, :binary, null: true
    add_column :submissions, :stderr_compressed, :binary, null: true
  end
end
