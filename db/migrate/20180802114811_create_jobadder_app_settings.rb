class CreateJobadderAppSettings < ActiveRecord::Migration
  def change
    create_table :jobadder_app_settings do |t|
      t.integer  :dataset_id
      t.string   :encrypted_ja_client_id
      t.string   :encrypted_ja_client_secret
      t.boolean  :import_jobs, default: false
      t.boolean  :import_jobs, default: false
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :authorised, default: false
      t.boolean  :custom_job_mapping, default: false
      t.boolean  :expire_closed_jobs, default: false
      t.string   :client_token
      t.string   :refresh_token
      t.string   :access_token
      t.string   :app_url
      t.datetime :access_token_expires_at
    end
  end
end