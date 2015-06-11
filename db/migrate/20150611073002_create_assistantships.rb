class CreateAssistantships < ActiveRecord::Migration
  def change
    create_table :assistantships do |t|
      t.references :user, index: true
      t.references :course, index: true

      t.timestamps
    end
  end
end
