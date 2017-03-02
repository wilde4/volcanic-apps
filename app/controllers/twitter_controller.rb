class TwitterController < ApplicationController
  protect_from_forgery with: :null_session
  after_filter :setup_access_control_origin
  
  def index

    render layout: false
  end
  
  def callback
  end

end
