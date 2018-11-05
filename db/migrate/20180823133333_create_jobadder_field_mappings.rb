class CreateJobadderFieldMappings < ActiveRecord::Migration
  def change
    create_table :jobadder_field_mappings do |t|
      t.integer  :jobadder_app_setting_id
      t.string   :jobadder_field_name
      t.string   :registration_question_reference
      t.datetime :created_at
      t.datetime :updated_at
      t.string   :job_attribute
    end
  end
end