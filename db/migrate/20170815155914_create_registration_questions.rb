class CreateRegistrationQuestions < ActiveRecord::Migration
  def change
    create_table :registration_questions do |t|
      t.string :user_group_name
      t.integer :user_group_id
      t.string :label
      t.string :reference
      t.string :core_reference
      t.string :profile_id
      t.string :uid
      t.timestamps null: false
    end
  end
end
