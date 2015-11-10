class AddSecureToKeys < ActiveRecord::Migration
  def change
    add_column :keys, :protocol, :string, default: 'http://'
  end
end
