class RenamePublishDateToPublishTime < ActiveRecord::Migration[4.2]
  def change
    rename_column :exercises, :publish_date, :publish_time
  end
end
