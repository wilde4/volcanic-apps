Apps::Application.routes.draw do
  root "welcome#index"

  get 'send_sms', :to => "text_local#send_sms", :as => :send_sms
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
    get "(/:id)/referral"       => 'referral#get_referral',         as: :get_referral
    get "(/:id)/referred"       => 'referral#get_referred',         as: :get_referred
    get "(/:id)/confirmed"      => 'referral#confirmed',            as: :referral_confirmed
    get "(/:id)/generate"       => 'referral#generate',             as: :referral_generate
    get "(/:id)/confirm"        => 'referral#confirm',              as: :referral_confirm
    get "(/:id)/revoke"         => 'referral#revoke',               as: :referral_revoke
    get "referrals_for_period"  => 'referral#referrals_for_period', as: :referrals_for_period
    get "most_referrals"        => 'referral#most_referrals',       as: :most_referrals
    get "funds_earned"          => 'referral#funds_earned',         as: :referral_fee_earned
    get "funds_owed"            => 'referral#funds_owed',           as: :referral_fee_owed
    get "(/:id)/paid"           => 'referral#paid',                 as: :referral_paid
  end

  scope :inventories do
    post "create_item"      => 'inventory#create_item',    as: :create_item
    get "index"             => 'inventory#index',          as: :inventory_index
    get "(/:id)/inventory"  => 'inventory#get_inventory',  as: :inventory_lookup
    get "/available"        => 'inventory#get_available',  as: :inventory_available
    get "new"               => 'inventory#new',            as: :inventory_new
    get "edit"              => 'inventory#edit',           as: :inventory_edit
    get "cheapest_price"    => 'inventory#cheapest_price', as: :inventory_cheapest_price
    patch "create_item"     => 'inventory#update',         as: :inventory_update
    post "activate_app"     => 'inventory#activate_app',   as: :inventory_activate_app
    post "deactivate_app"   => 'inventory#deactivate_app', as: :inventory_deactivate_app
    post "post_purchase"    => 'inventory#post_purchase',  as: :inventory_post_purchase
  end

  scope :evergrad_likes do
    post 'save_user' => 'evergrad_likes#save_user', as: :save_user
    post 'save_job' => 'evergrad_likes#save_job', as: :save_job
    post 'save_like' => 'evergrad_likes#save_like', as: :save_like
    get '(/:id)/likes_made' => 'evergrad_likes#likes_made', as: :user_likes_made
    get '(/:id)/likes_received' => 'evergrad_likes#likes_received', as: :user_likes_received
    get '(/:id)/matches' => 'evergrad_likes#matches', as: :user_matches
    get 'all_matches' => 'evergrad_likes#all_matches', as: :all_matches
    get 'notification_events' => 'evergrad_likes#notification_events', as: :notification_events
    get 'index' => 'evergrad_likes#index', as: :evergrad_likes_index
    get 'likes_csv' => 'evergrad_likes#likes_csv', as: :evergrad_likes_csv
    get 'jobs_paid' => 'evergrad_likes#jobs_paid', as: :evergrad_jobs_paid
  end
  
  # get 'send_email', :to => "end_points#send_email", :as => :send_email
end
