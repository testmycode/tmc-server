class AddAttachmentLogoToOrganizations < ActiveRecord::Migration
  def self.up
    change_table :organizations do |t|
      t.attachment :logo
    end
  end

  def self.down
    remove_attachment :organizations, :logo
  end
end
