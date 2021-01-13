class AddChecksumToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :checksum, :string, null: false, default: ''
  end
end
