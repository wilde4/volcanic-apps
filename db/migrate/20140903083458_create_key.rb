class CreateKey < ActiveRecord::Migration
  def change
    create_table :keys do |t|
      t.string :host
      t.integer :dataset_id
      t.string :api_key
      t.string :app_name
    end
  end
end
