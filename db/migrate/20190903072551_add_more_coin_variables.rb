class AddMoreCoinVariables < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :initial_coin_stash, :integer, null: true
    add_column :courses, :large_exercises_consume_more_coins, :boolean, default: false
  end
end
