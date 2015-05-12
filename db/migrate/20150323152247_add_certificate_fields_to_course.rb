class AddCertificateFieldsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :formal_name, :string
    add_column :courses, :certificate_downloadable, :boolean, default: false, null: false
    add_column :courses, :certificate_unlock_spec, :string
  end
end
