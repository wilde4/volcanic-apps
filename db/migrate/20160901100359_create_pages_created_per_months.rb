class CreatePagesCreatedPerMonths < ActiveRecord::Migration
  def change
    create_table :pages_created_per_months do |t|
      t.date :date
      t.integer :site_id
      t.integer :created_pages
      t.integer :total_pages

      t.timestamps
    end
  end
end
