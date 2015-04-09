class CreateYuTalentSettings < ActiveRecord::Migration
  def change
    create_table :yu_talent_settings do |t|
      t.integer :dataset_id
      t.string :client_id
      t.string :client_secret

      t.timestamps
    end
  end
end
