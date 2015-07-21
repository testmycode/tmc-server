class AddExternalScoreBoardUrlToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :external_scoreboard_url, :string
  end
end
