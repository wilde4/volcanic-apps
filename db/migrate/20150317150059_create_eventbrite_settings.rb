class CreateEventbriteSettings < ActiveRecord::Migration

  def change
    create_table :eventbrite_settings do |t|
      t.integer :dataset_id
      t.string :app_key
      t.string :user_key

      t.timestamps
    end]
  end

end
