Apps::Application.routes.draw do
  root "welcome#index"

  get 'send_sms', :to => "text_local#send_sms", :as => :send_sms
  post 'send_sms', :to => "text_local#send_sms", :as => :post_sms
  get 'skype', :to => "skype#consultant", :as => :skype
  get 'export-list', :to => "mail_chimp#export_list", :as => :export_list
  get 'related-videos', :to => "youtube#related_videos", :as => :related_videos
  get 'get-images', :to => "flickr#get_images", :as => :get_images
  get 'author', :to => "google_plus#author", :as => :author



  scope :mercury_xrm do
    get 'mercury_xrm_dashboard'  => 'mercury_xrm#mercury_xrm_dashboard'
    post "activate_app"     => 'pages_created_per_month#activate_app'
    post "deactivate_app"   => 'pages_created_per_month#deactivate_app'
  end

  

  scope :pages_created_per_month do
    get 'get_pages_created'  => 'pages_created_per_month#get_pages_created', as: :pages_created_per_month
    get 'calculate_pages_created'  => 'pages_created_per_month#calculate_pages_created', as: :calculate_pages_created
    post 'update_settings'  => 'pages_created_per_month#update_settings'
    post "activate_app"     => 'pages_created_per_month#activate_app'
    post "deactivate_app"   => 'pages_created_per_month#deactivate_app'
  end



  scope :referrals do
    get 'index'                 => 'referral#index',                as: :referrals_index
    post "create_referral"      => 'referral#create_referral',      as: :create_referral
    get "/referral"             => 'referral#referral_by_user',     as: :referral_by_user
    get "(/:id)/full_referral"  => 'referral#full_referral',        as: :full_referral
    get "(/:id)/referral"       => 'referral#get_referral',         as: :get_referral
    get "(/:id)/referred"       => 'referral#get_referred',         as: :get_referred
    get "(/:id)/confirmed"      => 'referral#confirmed',            as: :referral_confirmed
    get "(/:id)/generate"       => 'referral#generate',             as: :referral_generate
    post "confirm"              => 'referral#confirm',              as: :referral_confirm
    get "(/:id)/revoke"         => 'referral#revoke',               as: :referral_revoke
    get "referrals_for_period"  => 'referral#referrals_for_period', as: :referrals_for_period
    get "most_referrals"        => 'referral#most_referrals',       as: :most_referrals
    get "funds_earned"          => 'referral#funds_earned',         as: :referral_fee_earned
    get "funds_owed"            => 'referral#funds_owed',           as: :referral_fee_owed
    get "(/:id)/paid"           => 'referral#paid',                 as: :referral_paid
    get 'referral_report'   => 'referral#referral_report',      as: :referral_report
    get "payment_form"          => 'referral#payment_form',         as: :referral_payment_new
    patch "save_payment_info"   => 'referral#save_payment_info',    as: :referral_payment_save
    get 'notification_events' => 'referral#notification_events', as: :referral_notification_events
    post "activate_app"     => 'referral#activate_app',   as: :referral_activate_app
    post "deactivate_app"   => 'referral#deactivate_app', as: :referral_deactivate_app
  end

  scope :inventories do
    post "create_item"      => 'inventory#create_item',    as: :create_item
    get "index"             => 'inventory#index',          as: :inventory_index
    get "inventory_item"    => 'inventory#get_inventory',  as: :inventory_lookup
    get "/available"        => 'inventory#get_available',  as: :inventory_available
    get "new"               => 'inventory#new',            as: :inventory_new
    get "edit"              => 'inventory#edit',           as: :inventory_edit
    get "cheapest_price"    => 'inventory#cheapest_price', as: :inventory_cheapest_price
    get "best_options"      => 'inventory#best_options',   as: :inventory_best_options
    get "best_options_by_action"      => 'inventory#best_options_by_action',   as: :inventory_best_options_by_action
    get "available_actions" => 'inventory#available_actions', as: :inventory_available_actions
    patch "create_item"     => 'inventory#update',         as: :inventory_update
    post "activate_app"     => 'inventory#activate_app',   as: :inventory_activate_app
    post "deactivate_app"   => 'inventory#deactivate_app', as: :inventory_deactivate_app
    post "post_purchase"    => 'inventory#post_purchase',  as: :inventory_post_purchase
    get "delete"            => 'inventory#delete',         as: :inventory_delete
  end

  scope :evergrad_gaming do
    post "action_complete"        => 'evergrad_gaming#action_complete', as: :eg_action_complete
    get "available_achievements" => 'evergrad_gaming#available_achievements', as: :eg_available
    get "achievement"            => 'evergrad_gaming#achievement', as: :eg_achievement
    get "tiered_achievement"     => 'evergrad_gaming#tiered_achievement', as: :eg_achievement_tiered
  end

  scope :evergrad_likes do
    post 'save_user' => 'evergrad_likes#save_user', as: :save_user
    post 'save_job' => 'evergrad_likes#save_job', as: :save_job
    post 'save_like' => 'evergrad_likes#save_like', as: :save_like
    post 'delete_like' => 'evergrad_likes#delete_like', as: :delete_like
    get '(/:id)/likes_made' => 'evergrad_likes#likes_made', as: :user_likes_made
    get '(/:id)/likes_received' => 'evergrad_likes#likes_received', as: :user_likes_received
    get '(/:id)/matches' => 'evergrad_likes#matches', as: :user_matches
    get 'all_matches' => 'evergrad_likes#all_matches', as: :all_matches
    get 'notification_events' => 'evergrad_likes#notification_events', as: :notification_events
    get 'index' => 'evergrad_likes#index', as: :evergrad_likes_index
    get 'likes_csv' => 'evergrad_likes#likes_csv', as: :evergrad_likes_csv
    get 'jobs_paid' => 'evergrad_likes#jobs_paid', as: :evergrad_jobs_paid
    get 'overview' => 'evergrad_likes#overview', as: :evergrad_likes_overview
    get 'grad_overview' => 'evergrad_likes#grad_overview', as: :evergrad_grad_likes_overview
    post "activate_app"     => 'evergrad_likes#activate_app',   as: :evergrad_likes_activate_app
    post "deactivate_app"   => 'evergrad_likes#deactivate_app', as: :evergrad_likes_deactivate_app
    post 'unlike_user' => 'evergrad_likes#unlike_user', as: :evergrad_likes_unlike_user
    post 'unlike_job' => 'evergrad_likes#unlike_job', as: :evergrad_likes_unlike_job
  end

  scope :featured_jobs do
    post "update_featured"  => 'featured_jobs#update_featured'
    post "activate_app"     => 'featured_jobs#activate_app'
    post "deactivate_app"   => 'featured_jobs#deactivate_app'
    post "save_job"         => 'featured_jobs#save_job'
    post "destroy_job"      => 'featured_jobs#destroy_job'
    post "set_featured"     => 'featured_jobs#set_featured'
    get "featured"          => 'featured_jobs#featured'
    get 'index'             => 'featured_jobs#index', as: :featured_jobs_index
  end

  scope :talent_rover do
    post "update_settings"  => 'talent_rover#update_settings'
    post "activate_app"     => 'talent_rover#activate_app'
    post "deactivate_app"   => 'talent_rover#deactivate_app'
    post "parse_jobs"       => 'talent_rover#parse_jobs'
  end

  scope :leisure_jobs do
    post "update_settings"  => 'leisure_jobs#update_settings'
    post "activate_app"     => 'leisure_jobs#activate_app'
    post "deactivate_app"   => 'leisure_jobs#deactivate_app'
  end

  scope :eclipse do
    post 'update_settings'  => 'eclipse#update_settings'
    post 'activate_app'     => 'eclipse#activate_app'
    post 'deactivate_app'   => 'eclipse#deactivate_app'
  end

  scope :macildowie_daxtra do
    get "email_data"     => 'macildowie_daxtra#email_data'
    post 'save_user' => 'macildowie_daxtra#save_user'
    post 'save_job' => 'macildowie_daxtra#save_job'
    post "activate_app"     => 'macildowie_daxtra#activate_app',   as: :macildowie_daxtra_activate_app
    post "deactivate_app"   => 'macildowie_daxtra#deactivate_app', as: :macildowie_daxtra_deactivate_app
  end

  scope :indeed do
    post "activate_app"     => 'indeed#activate_app'
    post "deactivate_app"   => 'indeed#deactivate_app'
    get "index"             => 'indeed#index'
  end

  scope :broadbean do
    post "activate_app"     => 'broadbean#activate_app'
    post "deactivate_app"   => 'broadbean#deactivate_app'
    get "index"             => 'broadbean#index'
  end

  scope :logic_melon do
    post "activate_app"     => 'logic_melon#activate_app'
    post "deactivate_app"   => 'logic_melon#deactivate_app'
    get "index"             => 'logic_melon#index'
  end

  scope :idibu do
    post "activate_app"     => 'idibu#activate_app'
    post "deactivate_app"   => 'idibu#deactivate_app'
    get "index"             => 'idibu#index'
  end

  scope :talent_rover do
    post "activate_app"     => 'talent_rover#activate_app'
    post "deactivate_app"   => 'talent_rover#deactivate_app'
    get "index"             => 'talent_rover#index'
  end

  scope :recruitive do
    post "activate_app"     => 'recruitive#activate_app'
    post "deactivate_app"   => 'recruitive#deactivate_app'
    get "index"             => 'recruitive#index'
  end

  scope :zapier do
    get 'index'             => 'zapier#index'
    post "activate_app"     => 'zapier#activate_app'
    post "deactivate_app"   => 'zapier#deactivate_app'
  end
  
  scope :eventbrite do
    get  'index'            => 'eventbrite#index'
    # get  'check_access'     => 'eventbrite#check_access'
    get  'search'           => 'eventbrite#search'
    get  'import'           => 'eventbrite#import'
    post 'activate_app'     => 'eventbrite#activate_app'
    post 'deactivate_app'   => 'eventbrite#deactivate_app'
    post 'update_settings'  => 'eventbrite#update_settings'
    post "update_eventbrite_settings"  => 'eventbrite#update_eventbrite_settings', as: :eventbrite_settings_update
  end
  
  scope :bullhorn do
    get 'index'             => 'bullhorn#index'
    get 'jobs'              => 'bullhorn#jobs'
    get 'add_file_mapping_field' => 'bullhorn#add_file_mapping_field'
    get 'get_user'          => 'bullhorn#get_user'
    post "save_settings"    => 'bullhorn#save_settings'
    post 'save_user'        => 'bullhorn#save_user'
    post 'upload_cv'        => 'bullhorn#upload_cv'
    post 'job_application'  => 'bullhorn#job_application'
    post 'activate_app'     => 'bullhorn#activate_app'
    post 'deactivate_app'   => 'bullhorn#deactivate_app'
    post 'update_settings'  => 'bullhorn#update_settings'
    post 'new_search'       => 'bullhorn#new_search'
  end
  
  scope :bullhorn_v2 do
    get 'index'             => 'bullhorn_v2#index'
    get 'jobs'              => 'bullhorn_v2#jobs'
    get 'add_file_mapping_field' => 'bullhorn_v2#add_file_mapping_field'
    get 'get_user'          => 'bullhorn_v2#get_user'
    post "update"    => 'bullhorn_v2#update'
    post 'save_user'        => 'bullhorn_v2#save_user'
    post 'upload_cv'        => 'bullhorn_v2#upload_cv'
    post 'job_application'  => 'bullhorn_v2#job_application'
    post 'activate_app'     => 'bullhorn_v2#activate_app'
    post 'deactivate_app'   => 'bullhorn_v2#deactivate_app'
    post 'update_settings'  => 'bullhorn_v2#update_settings'
    post 'new_search'       => 'bullhorn_v2#new_search'
    get 'report'            => 'bullhorn_v2#report'
    get 'import_jobs/:id'       => 'bullhorn_v2#import_jobs'
  end

  scope :reed_global do
    get 'index'             => 'reed_global#index'
    post 'activate_app'     => 'reed_global#activate_app'
    post 'deactivate_app'   => 'reed_global#deactivate_app'
    post 'create_country'   => 'reed_global#create_country'
    post 'destroy_country'  => 'reed_global#destroy_country'
    post 'create_mapping'   => 'reed_global#create_mapping'
    post 'destroy_mapping'  => 'reed_global#destroy_mapping'
    get 'job_disciplines'   => 'reed_global#job_disciplines'
  end
  
  scope :semrush do
    get 'index'             => 'semrush#index'
    post 'activate_app'     => 'semrush#activate_app'
    post 'deactivate_app'   => 'semrush#deactivate_app'
    post 'save_settings'    => 'semrush#save_settings'
    post 'update_settings'  => 'semrush#update_settings'
  end
  
  scope :mail_chimp do
    get 'index'             => 'mail_chimp#index'
    post 'activate_app'     => 'mail_chimp#activate_app'
    post 'deactivate_app'   => 'mail_chimp#deactivate_app'
    get  'callback'         => 'mail_chimp#callback', as: :mail_chimp_callback
    get  "new_condition"    => 'mail_chimp#new_condition', as: :mail_chimp_new_condition
    post "save_condition"   => 'mail_chimp#save_condition'
    post "delete_condition" => 'mail_chimp#delete_condition', as: :mail_chimp_delete_condition
    post "classify_user"   => 'mail_chimp#classify_user'
    post "import_user_group"=> 'mail_chimp#import_user_group', as: :mail_chimp_import_user_group
  end

  scope :twitter do
    get 'index', to: 'twitter#index'
    get 'callback', to: 'twitter#callback'
    post 'activate_app', to: 'twitter#activate_app'
    post 'deactivate_app', to: 'twitter#deactivate_app'
    post 'post_tweet', to: 'twitter#post_tweet'
    post 'update', to: 'twitter#update'
    get 'disable', to: 'twitter#disable'
  end

  scope :job_adder do
    post "activate_app"     => 'job_adder#activate_app'
    post "deactivate_app"   => 'job_adder#deactivate_app'
    get  "index"            => 'job_adder#index'
    post "capture_jobs"     => 'job_adder#capture_jobs'
  end

  scope :yu_talent do
    post "activate_app"     => 'yu_talent#activate_app'
    post "deactivate_app"   => 'yu_talent#deactivate_app'
    post "update_settings"  => 'yu_talent#update_settings'
    get  "index"            => 'yu_talent#index'
    post "save_user"        => 'yu_talent#save_user'
    post "save_settings"    => 'yu_talent#save_settings'
    post 'upload_cv'        => 'yu_talent#upload_cv'
    get  "callback"         => 'yu_talent#callback', as: :yu_talent_callback
  end

  scope :arithon do
    post "activate_app"     => 'arithon#activate_app'
    post "deactivate_app"   => 'arithon#deactivate_app'
    post "update_settings"  => 'arithon#update_settings'
    get  "index"            => 'arithon#index'
    post "save_user"        => 'arithon#save_user'
    post "save_settings"    => 'arithon#save_settings'
    post 'upload_cv'        => 'arithon#upload_cv'
    get  "callback"         => 'arithon#callback', as: :arithon_callback
  end

  scope :bond_adapt do
    post "activate_app"     => 'bond_adapt#activate_app'
    post "deactivate_app"   => 'bond_adapt#deactivate_app'
    get  "index"            => 'bond_adapt#index'
    post "save_settings"    => 'bond_adapt#save_settings'
    post "save_user"        => 'bond_adapt#save_user'
  end

  scope :job_board do
    post "activate_app"     => 'job_board#activate_app'
    post "deactivate_app"   => 'job_board#deactivate_app'
    get  "index"            => 'job_board#index'
    get  "new"              => 'job_board#new', as: :new_job_board
    post "create"           => 'job_board#create'
    get  "edit"             => 'job_board#edit', as: :edit_job_board
    patch "update"          => 'job_board#update'
    get  "purchasable"      => 'job_board#purchasable'
    get  "require_tokens_for_jobs" => 'job_board#require_tokens_for_jobs'
    get  "access_for_cv_search"    => 'job_board#access_for_cv_search'
    post "increase_cv_access_time" => 'job_board#increase_cv_access_time'

    get  "form_attributes" => 'job_board#form_attributes'

    get  "salary_slider_attributes" => 'job_board#salary_slider_attributes'
    get  "deduct_cv_credit" => 'job_board#deduct_cv_credit'


    get  "client_form"      => 'job_board#client_form'
    post "client_create"    => 'job_board#client_create'

    get  "user_form"      => 'job_board#user_form'
    post "user_update"    => 'job_board#user_update'
  end

  scope :extra_form_fields do
    post "activate_app"     => 'extra_form_fields#activate_app'
    post "deactivate_app"   => 'extra_form_fields#deactivate_app'
    get 'index'             => 'extra_form_fields#index'
    get  "new"              => 'extra_form_fields#new', as: :new_form_field
    post "create"           => 'extra_form_fields#create'
    get "edit"              => 'extra_form_fields#edit'
    patch "update"          => 'extra_form_fields#update'

    get 'job_form'          => 'extra_form_fields#job_form'
  end

  scope :split_fee do
    post "activate_app"     => 'split_fee#activate_app'
    post "deactivate_app"   => 'split_fee#deactivate_app'
    get 'index'             => 'split_fee#index'
    get 'edit'              => 'split_fee#edit'
    patch 'update'          => 'split_fee#update'

    get 'job_form'          => 'split_fee#job_form'
    post 'job_create'       => 'split_fee#job_create'
    post 'job_expire'       => 'split_fee#job_expire'
    post 'job_destroy'      => 'split_fee#job_destroy'

    get 'current_split_fee' => 'split_fee#current_split_fee'
    get 'get_split_fee'     => 'split_fee#get_split_fee'
    get 'get_shared_candidate_split_fee'     => 'split_fee#get_shared_candidate_split_fee'

    get  'shared_candidate_form' =>     'split_fee#shared_candidate_form'
    post 'shared_candidate_create' =>   'split_fee#shared_candidate_create'
    post 'shared_candidate_destroy' =>  'split_fee#shared_candidate_destroy'
  end

  scope :filtered_notifications do
    post "activate_app"     => 'filtered_notifications#activate_app'
    post "deactivate_app"   => 'filtered_notifications#deactivate_app'
    get "app_notifications" => 'filtered_notifications#app_notifications'
    get "app_notifications_candidate_shared" => 'filtered_notifications#app_notifications_candidate_shared'
    post "send_notification" => 'filtered_notifications#send_notification'
    
    get "job_form"          => 'filtered_notifications#job_form'
    get "shared_candidate_form" => 'filtered_notifications#shared_candidate_form'

    post "modal_content"    => 'filtered_notifications#modal_content'
    patch "modal_content"    => 'filtered_notifications#modal_content'
  end

  scope :candidate_sharing do
    post "activate_app"     => 'candidate_sharing#activate_app'
    post "deactivate_app"   => 'candidate_sharing#deactivate_app'
    get "app_notifications" => 'candidate_sharing#app_notifications'
    post "send_notification" => 'candidate_sharing#send_notification'
  end

  scope :servicedott do
    get "email_data"     => 'servicedott#email_data'
    post "email_data"     => 'servicedott#email_data'
    post "activate_app"     => 'servicedott#activate_app'
    post "deactivate_app"   => 'servicedott#deactivate_app'
  end
  # get 'send_email', :to => "end_points#send_email", :as => :send_email

  scope :prs do
    get "email_data"     => 'prs#email_data'
    post "email_data"     => 'prs#email_data'
    post "activate_app"     => 'prs#activate_app'
    post "deactivate_app"   => 'prs#deactivate_app'
    get  "index"            => 'prs#index'
  end
  scope :daxtra do
    get "email_data"     => 'daxtra#email_data'
    post "email_data"     => 'daxtra#email_data'
    post "activate_app"     => 'daxtra#activate_app'
    post "deactivate_app"   => 'daxtra#deactivate_app'
    get  "index"            => 'daxtra#index'
  end

  resources :app_logs
  
  devise_for :profiles
  get "sso/:id" => "sessions#new"

  namespace :data_import do
    get "index" => "data_import#index"
    get "welcome" => "data_import#welcome"
    resources :files do
      get 'creating', :on => :collection
      get 'importing', :on => :member
      get 'updating', :on => :member
      get 'import', :on => :member
      get 'errors', :on => :member
      resources :headers
    end
    get "post_to_api" => "post_to_api#index"
    resources :registration_questions
  end

  # ===========
  # = API =
  # ===========

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      post "activate_app"     =>  'profiles#activate_app'
      post "deactivate_app"   =>  'profiles#deactivate_app'
    end
  end

  require 'sidekiq/web'
  authenticate :profile do
    mount Sidekiq::Web => '/sidekiq'
  end
end
