class DropArithonAppSettings < ActiveRecord::Migration
  def change
    drop_table :arithon_app_settings
  end
end
