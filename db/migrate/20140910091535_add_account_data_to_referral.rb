class AddAccountDataToReferral < ActiveRecord::Migration
  def change
    add_column :referrals, :account_name, :string
    add_column :referrals, :account_number, :string
    add_column :referrals, :sort_code, :string
  end
end
