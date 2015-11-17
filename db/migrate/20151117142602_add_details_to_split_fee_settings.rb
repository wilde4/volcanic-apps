class AddDetailsToSplitFeeSettings < ActiveRecord::Migration
  def change
    add_column :split_fee_settings, :details, :text
  end
end
