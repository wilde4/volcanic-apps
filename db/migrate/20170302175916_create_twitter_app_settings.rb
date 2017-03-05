class CreateTwitterAppSettings < ActiveRecord::Migration
  def change
    create_table :twitter_app_settings do |t|
      t.integer :dataset_id
      t.string :authorization_code
      t.timestamps
    end
  end
end
