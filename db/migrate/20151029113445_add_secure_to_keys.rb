class AddSecureToKeys < ActiveRecord::Migration
  def change
    add_column :keys, :secure, :boolean, default: 0
  end
end
