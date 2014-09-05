class AddPaidToLikesJob < ActiveRecord::Migration
  def change
    add_column :likes_jobs, :paid, :boolean, default: false
  end
end
