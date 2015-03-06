# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150306111602) do

  create_table "achievements", force: true do |t|
    t.integer "user_id"
    t.boolean "signed_up",         default: false
    t.boolean "downloaded_app",    default: false
    t.boolean "uploaded_cv",       default: false
    t.boolean "liked_job",         default: false
    t.boolean "shared_social",     default: false
    t.boolean "completed_profile", default: false
    t.string  "level"
  end

  create_table "app_settings", force: true do |t|
    t.integer "dataset_id"
    t.text    "settings"
  end

  create_table "bullhorn_users", force: true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.text     "user_data"
    t.text     "user_profile"
    t.text     "registration_answers"
    t.integer  "bullhorn_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "linkedin_profile"
  end

  create_table "featured_jobs", force: true do |t|
    t.integer "job_id"
    t.integer "user_id"
    t.integer "dataset_id"
    t.string  "job_reference"
    t.string  "job_title"
    t.text    "extra"
    t.date    "feature_start"
    t.date    "feature_end"
  end

  create_table "inventories", force: true do |t|
    t.string   "name"
    t.datetime "start_date"
    t.datetime "end_date"
    t.decimal  "price",         precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "object_action"
    t.integer  "dataset_id"
    t.string   "credit_type"
    t.string   "user_type"
  end

  create_table "keys", force: true do |t|
    t.string  "host"
    t.integer "app_dataset_id"
    t.string  "api_key"
    t.string  "app_name"
  end

  create_table "likes_jobs", force: true do |t|
    t.integer  "job_id"
    t.string   "job_reference"
    t.string   "job_title"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "extra"
    t.date     "expiry_date"
    t.boolean  "paid",          default: false
  end

  create_table "likes_likes", force: true do |t|
    t.integer  "like_id"
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type"
    t.text     "extra"
    t.boolean  "match",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "likes_likes", ["likeable_id", "likeable_type"], name: "index_likes_likes_on_likeable_id_and_likeable_type", using: :btree

  create_table "likes_users", force: true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.text     "extra"
    t.text     "registration_answers"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mac_daxtra_jobs", force: true do |t|
    t.integer  "job_id"
    t.text     "job"
    t.string   "job_type"
    t.text     "disciplines"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mac_daxtra_jobs", ["job_id"], name: "index_mac_daxtra_jobs_on_job_id", using: :btree

  create_table "mac_daxtra_users", force: true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "user_type"
    t.text     "user_profile"
    t.text     "registration_answers"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "referrals", force: true do |t|
    t.integer  "user_id"
    t.string   "token"
    t.boolean  "confirmed"
    t.datetime "confirmed_at"
    t.boolean  "revoked"
    t.datetime "revoked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "referred_by"
    t.string   "first_name"
    t.string   "last_name"
    t.decimal  "fee",            precision: 8, scale: 2
    t.boolean  "fee_paid",                               default: false
    t.string   "account_name"
    t.string   "account_number"
    t.string   "sort_code"
    t.integer  "dataset_id"
  end

  create_table "roles", force: true do |t|
    t.integer  "dataset_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "text_local_logs", force: true do |t|
    t.integer  "user_id"
    t.string   "mobile_number"
    t.text     "message"
    t.string   "sender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "yu_talent_settings", force: true do |t|
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "refresh_token"
  end

  create_table "yu_talent_users", force: true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.text     "user_data"
    t.text     "user_profile"
    t.text     "registration_answers"
    t.text     "linkedin_profile"
    t.integer  "yu_talent_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
