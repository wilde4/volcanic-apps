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
    post "create_referral"         => 'referral#create_referral',          as: :create_referral

    get "generate_referral_token"  => 'referral#generate_referral_token',  as: :generate_referral_token
    get "referral_token_exists"    => 'referral#referral_token_exists',    as: :referral_token_exists
    get "referrals_for_period"     => 'referral#referrals_for_period',     as: :referrals_for_period
    get "most_referrals"           => 'referral#most_referrals',           as: :most_referrals
    get "(/:id)/referral_token_confirmed" => 'referral#referral_token_confirmed', as: :referral_token_confirmed
    post "(/:id)/confirm_referral_token"  => 'referral#confirm_referral_token',   as: :confirm_referral_token
    post "(/:id)/revoke_referral"         => 'referral#revoke_referral',          as: :revoke_referral
  end
  
  # get 'send_email', :to => "end_points#send_email", :as => :send_email
end
