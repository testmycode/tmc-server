class AddReviews < ActiveRecord::Migration[4.2]
  def change
    add_column :available_points, :requires_review, :boolean, default: false, null: false

    create_table :reviews do |t|
      t.integer :submission_id, null: false
      t.integer :reviewer_id, null: true # Nullable just in case the reviewer user is deleted
      t.text :review_body, null: false
      t.timestamps
    end
    add_index :reviews, [:submission_id]
    add_index :reviews, [:reviewer_id]
    add_foreign_key :reviews, :submissions, on_delete: :cascade
    add_foreign_key :reviews, :users, column: 'reviewer_id', dependent: :nullify
  end
end
