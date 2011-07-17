class AssociateSubmissionWithUser < ActiveRecord::Migration
  def self.up
    drop_table :submissions
    create_table :submissions do |t|
      t.references :user
      t.references :exercise
      t.binary :return_file
      t.text :pretest_error
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    raise 'Irreversible'
  end
end
