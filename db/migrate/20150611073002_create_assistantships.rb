class CreateAssistantships < ActiveRecord::Migration[4.2]
  def change
    create_table :assistantships do |t|
      t.references :user, dependent: :delete
      t.references :course, dependent: :delete

      t.timestamps
    end
    add_index :assistantships, [:user_id, :course_id], unique: true
  end
end
