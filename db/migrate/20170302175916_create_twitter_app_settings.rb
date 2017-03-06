class CreateTwitterAppSettings < ActiveRecord::Migration
  def change
    create_table :twitter_app_settings do |t|
      t.integer :dataset_id
      t.string :access_token
      t.string :access_token_secret
      t.string :tweet
      t.timestamps
    end
  end
end
