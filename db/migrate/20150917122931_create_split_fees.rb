class CreateSplitFees < ActiveRecord::Migration
  def change
    create_table :split_fees do |t|
      t.integer :app_dataset_id
      t.integer :job_id
      t.text :salary_band
      t.integer :fee_percentage
      t.text :terms_of_fee
      t.datetime :expiry_date

      t.timestamps

    end
  end
end
