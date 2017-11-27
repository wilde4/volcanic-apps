class AddEncodingToDataImportFiles < ActiveRecord::Migration
  def change
    add_column :data_import_files, :encoding, :string
  end
end
