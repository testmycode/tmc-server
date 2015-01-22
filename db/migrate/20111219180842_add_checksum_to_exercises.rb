class AddChecksumToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :checksum, :string, null: false, default: ''
  end
end
