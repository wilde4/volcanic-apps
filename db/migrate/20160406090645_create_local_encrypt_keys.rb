class CreateLocalEncryptKeys < ActiveRecord::Migration
  def change
    create_table :local_env_vars do |t|
      t.text :name
      t.text :value
    end
  end
end
