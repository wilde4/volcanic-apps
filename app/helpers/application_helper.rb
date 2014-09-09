module ApplicationHelper

  # Fix any app-relative links depending whether it's routed correctly
  def relative_link(path)
     # no id will be given on <path>
    path.prepend("#{params[:data][:id]}/") if params[:data][:label].nil?
    path
  end

end
