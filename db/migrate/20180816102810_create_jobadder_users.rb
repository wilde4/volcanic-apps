class CreateJobadderUsers < ActiveRecord::Migration
  def change
    create_table :jobadder_users do |t|
      t.integer  :user_id
      t.string   :email
      t.text     :user_data
      t.text     :user_profile
      t.text     :registration_answers
      t.integer  :jobadder_id
      t.datetime :created_at
      t.datetime :updated_at
      t.text     :linkedin_profile
      t.string   :sent_upload_ids
      t.text     :legal_documents
    end
  end
end