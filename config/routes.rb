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
    post "create_referral"      => 'referral#create_referral',      as: :create_referral
    get "(/:id)/referral"       => 'referral#get_referral',         as: :get_referral
    get "(/:id)/referred"       => 'referral#get_referred',         as: :get_referred
    get "(/:id)/confirmed"      => 'referral#confirmed',            as: :referral_confirmed
    get "(/:id)/generate"       => 'referral#generate',             as: :referral_generate
    get "(/:id)/confirm"       => 'referral#confirm',              as: :referral_confirm
    get "(/:id)/revoke"        => 'referral#revoke',               as: :referral_revoke
    get "referrals_for_period"  => 'referral#referrals_for_period', as: :referrals_for_period
    get "most_referrals"        => 'referral#most_referrals',       as: :most_referrals
  end

  scope :promotions do
    post "create_promotion"     => 'promotion#create_promotion', as: :create_promotion
    get  "(/:id)/promotion"     => 'promotion#get_promotion',    as: :get_promotion
    get  "(/:id)/active"        => 'promotion#active',           as: :promotion_active
    get  "(/:id)/toggle_active" => 'promotion#toggle_active',    as: :promotion_toggle_active
    get  "(/:id)/toggle_default" => 'promotion#toggle_default',  as: :promotion_toggle_default
    get  "/promotion"            => 'promotion#promotion_for_role', as: :promotion_for_role

    get "overview"              => 'promotion#overview',         as: :promotion_overview
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
  end
  
  # get 'send_email', :to => "end_points#send_email", :as => :send_email
end
