class CreatePagesCreatedPerMonths < ActiveRecord::Migration
  def change
    create_table :pages_created_per_months do |t|
      t.string :url
      t.date :date_added
      t.date :date_deleted

      t.timestamps
    end
  end
end
