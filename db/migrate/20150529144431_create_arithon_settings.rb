class CreateArithonSettings < ActiveRecord::Migration
  def change
    create_table :arithon_settings do |t|
      t.integer :dataset_id
      t.string :api_key
      t.string :company_name

      t.timestamps
    end
  end
end
