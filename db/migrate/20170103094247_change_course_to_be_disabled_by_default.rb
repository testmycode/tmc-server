class ChangeCourseToBeDisabledByDefault < ActiveRecord::Migration
  def change
    change_column_default(:courses, :disabled_status, 1)
  end
end
