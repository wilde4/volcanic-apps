class CreateEtzSettings < ActiveRecord::Migration
  def change
    create_table :etz_settings do |t|
    	t.references :dataset, index: true, null: false
    	t.string :url
      t.timestamps
    end
  end
end
