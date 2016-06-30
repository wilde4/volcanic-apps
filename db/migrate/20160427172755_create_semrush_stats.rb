class CreateSemrushStats < ActiveRecord::Migration
  def change
    create_table :semrush_stats do |t|
      t.integer :dataset_id
      t.string :domain
      t.string :keyword
      t.integer :position
      t.integer :position_difference
      t.float :traffic_percent
      t.float :costs_percent
      t.integer :results
      t.float :cpc
      t.integer :volume
      t.string :url
      t.date :day
      t.string :engine
      t.timestamps null: false
    end
  end
end
