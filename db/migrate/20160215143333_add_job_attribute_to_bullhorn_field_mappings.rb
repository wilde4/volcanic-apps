class AddJobAttributeToBullhornFieldMappings < ActiveRecord::Migration
  def change
    add_column :bullhorn_field_mappings, :job_attribute, :string
  end
end
