class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.string :host
      t.string :api_key
      t.boolean :enable
      t.integer :app_dataset_id

      t.timestamps null: false
    end
  end
end
