class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.string :name
      t.binary :pdf
      t.references :user
      t.references :course

      t.timestamps
    end
  end
end
