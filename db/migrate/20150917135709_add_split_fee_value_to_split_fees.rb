class AddSplitFeeValueToSplitFees < ActiveRecord::Migration
  def change
    add_column :split_fees, :split_fee_value, :integer
  end
end
