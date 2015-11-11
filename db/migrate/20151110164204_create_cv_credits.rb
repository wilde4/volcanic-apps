class CreateCvCredits < ActiveRecord::Migration
  def change
    create_table :cv_credits do |t|
      t.integer :app_dataset_id
      t.string :client_token
      t.integer :credits_added
      t.integer :credits_spent
      t.boolean :expired
      t.datetime :expiry_date
      t.timestamps
    end
  end
end
