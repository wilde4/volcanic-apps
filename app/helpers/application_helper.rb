module ApplicationHelper

  # Fix any app-relative links depending whether it's routed correctly
  def relative_link(path)
     # no id will be given on <path>
    path.prepend("#{params[:data][:id]}/") #if params[:data][:id].nil?
    path
  end

    # Use the app server suitable for the host environment
  def app_server_host
    if Rails.env.development?
      "localhost:3001"
    elsif Rails.env.production?
      "apps.volcanic.co"
    end
  end

end
