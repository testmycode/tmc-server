class AddParamsToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :params_json, :text
  end
end
