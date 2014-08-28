class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :active
      t.decimal :price, precision: 8, scale: 2
      t.boolean :default, default: false
      t.belongs_to :role, index: true

      t.timestamps
    end
  end
end
