class AddSoftDeadlineToExcercises < ActiveRecord::Migration
  def change
    add_column :exercises, :soft_deadline_spec, :text
  end
end
