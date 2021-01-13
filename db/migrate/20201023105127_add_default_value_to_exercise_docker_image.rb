class AddDefaultValueToExerciseDockerImage < ActiveRecord::Migration[4.2]
  def change
    change_column :exercises, :docker_image, :string, :default => "eu.gcr.io/moocfi-public/tmc-sandbox-tmc-langs-rust"
  end
end
  