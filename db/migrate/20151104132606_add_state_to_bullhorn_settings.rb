class AddStateToBullhornSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :status_text, :string
  end
end
