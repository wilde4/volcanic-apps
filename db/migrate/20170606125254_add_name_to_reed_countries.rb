class AddNameToReedCountries < ActiveRecord::Migration
  def change
    add_column :reed_countries, :name, :string
  end
end
