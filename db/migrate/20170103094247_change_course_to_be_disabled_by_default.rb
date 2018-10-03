class ChangeCourseToBeDisabledByDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:courses, :disabled_status, 1)
  end
end
