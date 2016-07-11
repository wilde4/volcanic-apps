class CreateMailChimpAppSettings < ActiveRecord::Migration
  def change
    create_table :mail_chimp_app_settings do |t|
      t.integer :dataset_id
      t.string :authorization_code
      t.text :access_token
      t.timestamps
    end
  end
end
