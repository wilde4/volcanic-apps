class CreateAppLog < ActiveRecord::Migration
  def change
    create_table :app_logs do |t|
      t.references :loggable, polymorphic: true, index: true
      t.references :key, index: true
      t.string :endpoint
      t.text :message
      t.text :response
      t.string :name
      t.boolean :error, default: false
      t.boolean :internal, default: false

      t.timestamps
    end
  end
end
