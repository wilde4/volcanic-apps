class CreateArithon < ActiveRecord::Migration
  def change
    create_table "arithon_app_settings", force: true do |t|
      t.integer  "dataset_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "authorization_code"
      t.text     "access_token"
      t.string   "background_info"
      t.string   "company_name"
      t.string   "location"
      t.string   "history"
      t.string   "education"
      t.string   "facebook"
      t.string   "linkedin"
      t.string   "phone"
      t.string   "phone_mobile"
      t.string   "position"
    end

    create_table "arithon_users", force: true do |t|
      t.integer  "user_id"
      t.string   "email"
      t.text     "user_data"
      t.text     "user_profile"
      t.text     "registration_answers"
      t.text     "linkedin_profile"
      t.integer  "arithon_uid"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "project_id"
      t.string   "status_id"
      t.integer  "type_id"
    end
  end
end
