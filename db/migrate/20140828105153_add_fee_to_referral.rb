class AddFeeToReferral < ActiveRecord::Migration
  def change
    add_column :referrals, :fee, :decimal, precision: 8, scale: 2
    add_column :referrals, :fee_paid, :boolean, default: false
  end
end
