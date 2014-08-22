class AddReferredByToReferral < ActiveRecord::Migration
  def change
    add_column :referrals, :referred_by, :integer
  end
end
