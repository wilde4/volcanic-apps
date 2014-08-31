class AddFieldsToLikesJob < ActiveRecord::Migration
  def change
    add_column :likes_jobs, :extra, :text
    remove_column :likes_jobs, :cached_slug, :string
    add_column :likes_jobs, :expiry_date, :date
  end
end
