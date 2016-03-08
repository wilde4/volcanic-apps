class CreateBullhornFieldMappings < ActiveRecord::Migration
  def change
    create_table :bullhorn_field_mappings do |t|
      t.references :bullhorn_app_setting, index: true
      t.string :bullhorn_field_name
      t.string :registration_question_reference
      t.boolean :sync_from_bullhorn, default: 0

      t.timestamps
    end
  end
end
