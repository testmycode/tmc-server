class AddParamsToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :params_json, :text
  end
end
