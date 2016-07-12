class CreateSemrushAppSettings < ActiveRecord::Migration
  def change
    create_table :semrush_app_settings do |t|
      t.integer :dataset_id
      t.integer :keyword_amount
      t.integer :request_rate
      t.integer :previous_data
      t.string :engine
      t.string :domain
      t.timestamps
    end
  end
end
