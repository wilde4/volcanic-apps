Apps::Application.routes.draw do
  root "welcome#index"

  get 'send_sms', :to => "text_local#send_sms", :as => :send_sms
  post 'send_sms', :to => "text_local#send_sms", :as => :post_sms
  get 'related-events', :to => "event_brite#related_events", :as => :related_events
  get 'skype', :to => "skype#consultant", :as => :skype
  get 'export-list', :to => "mail_chimp#export_list", :as => :export_list
  get 'related-videos', :to => "youtube#related_videos", :as => :related_videos
  get 'get-images', :to => "flickr#get_images", :as => :get_images
  get 'author', :to => "google_plus#author", :as => :author

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
    patch "create_item"     => 'inventory#update',         as: :inventory_update
    post "activate_app"     => 'inventory#activate_app',   as: :inventory_activate_app
    post "deactivate_app"   => 'inventory#deactivate_app', as: :inventory_deactivate_app
    post "post_purchase"    => 'inventory#post_purchase',  as: :inventory_post_purchase
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

  scope :bullhorn do
    get 'index'             => 'bullhorn#index'
    get 'jobs'              => 'bullhorn#jobs'
    post 'save_user'        => 'bullhorn#save_user'
    post 'upload_cv'        => 'bullhorn#upload_cv'
    post 'job_application'  => 'bullhorn#job_application'
    post 'activate_app'     => 'bullhorn#activate_app'
    post 'deactivate_app'   => 'bullhorn#deactivate_app'
    post 'update_settings'  => 'bullhorn#update_settings'
    post 'new_search'       => 'bullhorn#new_search'
  end

  scope :yu_talent do
    post "activate_app"     => 'yu_talent#activate_app'
    post "deactivate_app"   => 'yu_talent#deactivate_app'
    post "update_settings"  => 'yu_talent#update_settings'
    get  "index"            => 'yu_talent#index'
    post "save_user"        => 'yu_talent#save_user'
    post "save_settings"    => 'yu_talent#save_settings'
    get  "callback"         => 'yu_talent#callback', as: :yu_talent_callback
  end

  # get 'send_email', :to => "end_points#send_email", :as => :send_email
end
