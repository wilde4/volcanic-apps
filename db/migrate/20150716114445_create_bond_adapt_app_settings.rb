class CreateBondAdaptAppSettings < ActiveRecord::Migration
  def change
    create_table :bond_adapt_app_settings do |t|
      t.integer :dataset_id
      t.string :username
      t.string :password
      t.string :domain
      t.string :domain_profile
      t.string :endpoint

      t.timestamps
    end
  end
end
