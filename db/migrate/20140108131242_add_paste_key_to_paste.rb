class AddPasteKeyToPaste < ActiveRecord::Migration
  def up
    add_column :submissions, :paste_key, :string, unique: true, index: true
    #add_index :submissions, [:paste_key], unique: true

    ActiveRecord::Base.connection.transaction(:requires_new => true) do
      Submission.where(paste_available: true).each do |submission|
        submission.set_paste_key_if_paste_available
        submission.save!
      end
    end

  end

  def down
    remove_column :submissions, :paste_key
  end
end
