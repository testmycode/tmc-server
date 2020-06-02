class AddDockerImageToExercise < ActiveRecord::Migration
  def change
    add_column :exercises, :docker_image, :string, null: true
  end
end
