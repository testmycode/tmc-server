class AddSoftDeadlineToExcercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :soft_deadline_spec, :text
  end
end
