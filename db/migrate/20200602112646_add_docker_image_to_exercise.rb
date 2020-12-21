class AddDockerImageToExercise < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :docker_image, :string, null: true
  end
end
