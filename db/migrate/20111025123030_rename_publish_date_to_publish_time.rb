class RenamePublishDateToPublishTime < ActiveRecord::Migration
  def change
    rename_column :exercises, :publish_date, :publish_time
  end
end
