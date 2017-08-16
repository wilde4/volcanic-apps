class SessionsController < ApplicationController
  skip_before_action :authenticate_profile!

  def new
    resource = Profile.find_by api_key: params[:id]
    if resource
      sign_in :profile, resource, bypass: true
      cookies[:profile_domain] = resource.host
      redirect_to params[:redirect_url]
    else
      render text: "fail"
    end
  end

end
