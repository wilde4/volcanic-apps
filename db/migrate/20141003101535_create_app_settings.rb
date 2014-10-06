class CreateAppSettings < ActiveRecord::Migration
  def change
    create_table :app_settings do |t|
      t.integer :dataset_id
      t.text :settings
    end
  end
end
