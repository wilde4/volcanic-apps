class CreateDataImportHeaders < ActiveRecord::Migration
  def change
    create_table :data_import_headers do |t|
      t.string :name
      t.string :mapping
      t.references :data_import_file, index: true
      t.references :registration_question, index: true
      t.boolean  :multiple_answers, default: false
      t.string   :column_name
      t.boolean  :nl2br, default: false

      t.timestamps null: false
    end
  end
end
