class CreateDataImportLines < ActiveRecord::Migration
  def change
    create_table :data_import_lines do |t|
      t.integer :number
      t.text :values
      t.text :error_messages
      t.boolean :error, default: false
      t.boolean :processed, default: false
      t.references :data_import_file, index: true
      t.string :uid

      t.timestamps null: false
    end
  end
end
