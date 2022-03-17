class AddAttachmentLogoToOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    change_table :organizations do |t|
      # t.attachment :logo
      t.string :logo_file_name
      t.string :logo_content_type
      t.integer :logo_file_size
      t.timestamp :logo_updated_at
    end
  end

  def self.down
    remove_attachment :organizations, :logo
  end
end
