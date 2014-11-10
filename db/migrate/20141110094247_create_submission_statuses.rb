class CreateSubmissionStatuses < ActiveRecord::Migration
  def change
    create_table :submission_statuses do |t|
      t.string :value
      t.integer :number

      t.timestamps
    end
  end
end
