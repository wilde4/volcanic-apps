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

ActiveRecord::Schema.define(version: 20170608103421) do

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

  create_table "app_logs", force: true do |t|
    t.integer  "loggable_id"
    t.string   "loggable_type"
    t.integer  "key_id"
    t.string   "endpoint"
    t.text     "message"
    t.text     "response"
    t.string   "name"
    t.boolean  "error",         default: false
    t.boolean  "internal",      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "app_logs", ["key_id"], name: "index_app_logs_on_key_id", using: :btree
  add_index "app_logs", ["loggable_id", "loggable_type"], name: "index_app_logs_on_loggable_id_and_loggable_type", using: :btree

  create_table "app_settings", force: true do |t|
    t.integer "dataset_id"
    t.text    "settings"
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
  end

  create_table "bond_adapt_app_settings", force: true do |t|
    t.integer  "dataset_id"
    t.string   "username"
    t.string   "password"
    t.string   "domain"
    t.string   "domain_profile"
    t.string   "endpoint"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bullhorn_app_settings", force: true do |t|
    t.integer  "dataset_id"
    t.string   "encrypted_bh_username"
    t.string   "encrypted_bh_password"
    t.string   "encrypted_bh_client_id"
    t.string   "encrypted_bh_client_secret"
    t.boolean  "import_jobs",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "linkedin_bullhorn_field"
    t.string   "source_text"
    t.boolean  "always_create",              default: false
    t.boolean  "authorised",                 default: false
    t.string   "status_text"
    t.string   "cv_type_text"
    t.boolean  "uses_public_filter",         default: false
    t.boolean  "custom_job_mapping",         default: false
    t.boolean  "expire_closed_jobs",         default: false
  end

  create_table "bullhorn_field_mappings", force: true do |t|
    t.integer  "bullhorn_app_setting_id"
    t.string   "bullhorn_field_name"
    t.string   "registration_question_reference"
    t.boolean  "sync_from_bullhorn",              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "job_attribute"
  end

  add_index "bullhorn_field_mappings", ["bullhorn_app_setting_id"], name: "index_bullhorn_field_mappings_on_bullhorn_app_setting_id", using: :btree

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

  create_table "client_vat_rates", force: true do |t|
    t.string  "client_token"
    t.decimal "vat_rate",     precision: 8, scale: 2
  end

  create_table "cv_credits", force: true do |t|
    t.integer  "app_dataset_id"
    t.string   "client_token"
    t.integer  "credits_added"
    t.integer  "credits_spent"
    t.boolean  "expired"
    t.datetime "expiry_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cv_search_access_durations", force: true do |t|
    t.integer  "app_dataset_id"
    t.string   "user_token"
    t.integer  "duration_added"
    t.datetime "expiry_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "client_token"
  end

  add_index "cv_search_access_durations", ["app_dataset_id"], name: "index_cv_search_access_durations_on_app_dataset_id", using: :btree
  add_index "cv_search_access_durations", ["client_token"], name: "index_cv_search_access_durations_on_client_token", using: :btree
  add_index "cv_search_access_durations", ["user_token"], name: "index_cv_search_access_durations_on_user_token", using: :btree

  create_table "cv_search_settings", force: true do |t|
    t.integer "job_board_id"
    t.boolean "charge_for_cv_search"
    t.boolean "require_access_for_cv_search"
    t.decimal "cv_search_price",              precision: 8, scale: 2
    t.integer "cv_search_duration"
    t.string  "cv_search_title"
    t.text    "cv_search_description"
    t.boolean "cv_search_enabled",                                    default: true
    t.string  "access_control_type"
    t.decimal "cv_credit_price",              precision: 8, scale: 2
    t.integer "cv_credit_expiry_duration"
    t.string  "cv_credit_title"
    t.text    "cv_credit_description"
  end

  create_table "eventbrite_settings", force: true do |t|
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_token"
  end

  create_table "extra_form_fields", force: true do |t|
    t.integer  "app_dataset_id"
    t.string   "form"
    t.string   "param_key"
    t.string   "label"
    t.string   "hint"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  add_index "featured_jobs", ["job_id"], name: "index_featured_jobs_on_job_id", using: :btree

  create_table "filtered_notification_sendings", force: true do |t|
    t.integer  "job_id"
    t.text     "client_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
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
    t.string   "user_group"
    t.string   "currency",                              default: "GBP"
  end

  create_table "job_boards", force: true do |t|
    t.integer  "app_dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency"
    t.string   "company_number"
    t.string   "vat_number"
    t.string   "phone_number"
    t.text     "address"
    t.boolean  "charge_vat"
    t.decimal  "default_vat_rate",    precision: 8, scale: 2
    t.integer  "salary_min"
    t.integer  "salary_max"
    t.integer  "salary_step"
    t.integer  "salary_from"
    t.integer  "salary_to"
    t.integer  "disciplines_limit",                           default: 0
    t.integer  "job_functions_limit",                         default: 0
    t.integer  "key_locations_limit",                         default: 0
    t.text     "posting_currencies"
  end

  add_index "job_boards", ["app_dataset_id"], name: "index_job_boards_on_app_dataset_id", using: :btree

  create_table "job_token_settings", force: true do |t|
    t.integer "job_board_id"
    t.boolean "charge_for_jobs"
    t.boolean "require_tokens_for_jobs"
    t.decimal "job_token_price",         precision: 8, scale: 2
    t.string  "job_token_title"
    t.text    "job_token_description"
    t.integer "job_duration"
  end

  create_table "keys", force: true do |t|
    t.string  "host"
    t.integer "app_dataset_id"
    t.string  "api_key"
    t.string  "app_name"
    t.string  "protocol",       default: "http://"
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

  create_table "local_env_vars", force: true do |t|
    t.text "name"
    t.text "value"
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
    t.string   "user_group_name"
    t.text     "user_profile"
    t.text     "registration_answers"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_chimp_app_settings", force: true do |t|
    t.integer  "dataset_id"
    t.string   "authorization_code"
    t.text     "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "importing_users"
  end

  create_table "mail_chimp_conditions", force: true do |t|
    t.integer  "mail_chimp_app_settings_id"
    t.integer  "user_group"
    t.string   "mail_chimp_list_id"
    t.string   "registration_question_reference"
    t.text     "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_chimp_conditions", ["mail_chimp_app_settings_id"], name: "index_mail_chimp_conditions_on_mail_chimp_app_settings_id", using: :btree

  create_table "pages_created_per_months", force: true do |t|
    t.string   "url"
    t.date     "date_added"
    t.date     "date_deleted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_id"
  end

  create_table "reed_countries", force: true do |t|
    t.integer  "dataset_id"
    t.string   "country_reference"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "reed_countries", ["dataset_id", "country_reference"], name: "index_reed_countries_on_dataset_id_and_country_reference", unique: true, using: :btree
  add_index "reed_countries", ["dataset_id"], name: "index_reed_countries_on_dataset_id", using: :btree

  create_table "reed_mappings", force: true do |t|
    t.integer  "discipline_id"
    t.integer  "job_function_id"
    t.integer  "reed_country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reed_mappings", ["job_function_id"], name: "index_reed_mappings_on_job_function_id", using: :btree
  add_index "reed_mappings", ["reed_country_id"], name: "index_reed_mappings_on_reed_country_id", using: :btree

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

  create_table "semrush_app_settings", force: true do |t|
    t.integer  "dataset_id"
    t.integer  "keyword_amount"
    t.integer  "request_rate"
    t.integer  "previous_data"
    t.string   "engine"
    t.string   "domain"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "last_petition_at"
  end

  create_table "semrush_stats", force: true do |t|
    t.integer  "dataset_id"
    t.string   "domain"
    t.string   "keyword"
    t.integer  "position"
    t.integer  "position_difference"
    t.float    "traffic_percent"
    t.float    "costs_percent"
    t.integer  "results",                 limit: 8
    t.float    "cpc"
    t.integer  "volume"
    t.string   "url"
    t.date     "day"
    t.string   "engine"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "semrush_app_settings_id"
  end

  add_index "semrush_stats", ["semrush_app_settings_id"], name: "index_semrush_stats_on_semrush_app_settings_id", using: :btree

  create_table "split_fee_settings", force: true do |t|
    t.integer  "app_dataset_id"
    t.text     "salary_bands"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "details"
  end

  create_table "split_fees", force: true do |t|
    t.integer  "app_dataset_id"
    t.integer  "job_id"
    t.text     "salary_band"
    t.integer  "fee_percentage"
    t.text     "terms_of_fee"
    t.datetime "expiry_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "split_fee_value"
    t.integer  "user_id"
  end

  create_table "text_local_logs", force: true do |t|
    t.integer  "user_id"
    t.string   "mobile_number"
    t.text     "message"
    t.string   "sender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twitter_app_settings", force: true do |t|
    t.integer  "dataset_id"
    t.string   "access_token"
    t.string   "access_token_secret"
    t.string   "tweet"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "only_featured",       default: false
  end

  create_table "yu_talent_app_settings", force: true do |t|
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
    t.integer  "project_id"
    t.string   "status_id"
    t.integer  "type_id"
  end

end
