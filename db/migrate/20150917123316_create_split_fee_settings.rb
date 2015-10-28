class CreateSplitFeeSettings < ActiveRecord::Migration
  def change
    create_table :split_fee_settings do |t|
      t.integer :app_dataset_id
      t.text :salary_bands

      t.timestamps
    end
  end
end
