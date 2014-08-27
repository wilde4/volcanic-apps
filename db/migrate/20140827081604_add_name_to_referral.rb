class AddNameToReferral < ActiveRecord::Migration
  def change
  	add_column :referrals, :first_name, :string
  	add_column :referrals, :last_name, :string
  end
end
