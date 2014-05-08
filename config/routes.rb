Apps::Application.routes.draw do
  root "welcome#index"
  get 'send_sms', :to => "text_local#send_sms", :as => :send_sms
  get 'related-events', :to => "event_brite#related_events", :as => :related_events
  get 'skype', :to => "skype#consultant", :as => :skype
  get 'export-list', :to => "mail_chimp#export_list", :as => :export_list

  # get 'send_email', :to => "end_points#send_email", :as => :send_email
end
