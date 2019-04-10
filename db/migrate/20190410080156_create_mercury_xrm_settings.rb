class CreateMercuryXrmSettings < ActiveRecord::Migration
  def change
    create_table :mercury_xrm_settings do |t|
      t.integer :dataset_id
      t.text :settings

      t.timestamps
    end
  end
end
