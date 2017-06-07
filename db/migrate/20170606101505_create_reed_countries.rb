class CreateReedCountries < ActiveRecord::Migration
  def change
    create_table :reed_countries do |t|
      t.integer :dataset_id
      t.string :country_reference

      t.timestamps
    end
    add_index :reed_countries, :dataset_id
    add_index :reed_countries, [:dataset_id, :country_reference], unique: true
  end
end
