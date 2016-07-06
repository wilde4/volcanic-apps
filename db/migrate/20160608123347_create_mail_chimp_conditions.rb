class CreateMailChimpConditions < ActiveRecord::Migration
  def change
    create_table :mail_chimp_conditions do |t|
      t.belongs_to :mail_chimp_app_settings, index: true
      t.integer :user_group
      t.integer :mail_chimp_list_id
      t.integer :registration_question_id
      t.text :answer
      t.timestamps
    end
  end
end
