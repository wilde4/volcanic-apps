class CreateReedMappings < ActiveRecord::Migration
  def change
    create_table :reed_mappings do |t|
      t.integer :discipline_id
      t.integer :job_function_id
      t.references :reed_country, index: true

      t.timestamps
    end
    add_index :reed_mappings, :job_function_id
  end
end
