class AddDatasetIdToRegistrationBonuses < ActiveRecord::Migration
  def change
    add_column :registration_bonuses, :dataset_id, :integer
  end
end
