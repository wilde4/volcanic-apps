class AddFieldsToCvSearchSettings < ActiveRecord::Migration
  def change
    add_column :cv_search_settings, :access_control_type, :string
    add_column :cv_search_settings, :cv_credit_price, :decimal, :precision => 8, :scale => 2
    add_column :cv_search_settings, :cv_credit_expiry_duration, :integer
    add_column :cv_search_settings, :cv_credit_title, :string
    add_column :cv_search_settings, :cv_credit_description, :text
  end
end
