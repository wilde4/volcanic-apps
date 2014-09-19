class AddDatasetIdToReferrals < ActiveRecord::Migration
  def change
    add_column :referrals, :dataset_id, :integer
  end
end
