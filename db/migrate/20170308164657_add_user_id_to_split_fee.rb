class AddUserIdToSplitFee < ActiveRecord::Migration
  def change
    add_column :split_fees, :user_id, :integer
  end
end
