class CreateBullhornReportEntries < ActiveRecord::Migration
  def change
    create_table :bullhorn_report_entries do |t|
      t.references :key, index: true
      t.date :date, index: true
      t.integer :job_create_count, default: 0
      t.integer :job_expire_count, default: 0
      t.integer :job_delete_count, default: 0
      t.integer :job_failed_count, default: 0
      t.integer :user_create_count, default: 0
      t.integer :user_update_count, default: 0
      t.integer :user_failed_count, default: 0
      t.integer :applications_count, default: 0
    end
    add_index :bullhorn_report_entries, :date
  end
end
