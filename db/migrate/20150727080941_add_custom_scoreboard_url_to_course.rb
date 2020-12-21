class AddCustomScoreboardUrlToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :external_scoreboard_url, :string
  end
end
