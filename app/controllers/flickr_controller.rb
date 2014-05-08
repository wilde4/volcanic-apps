class FlickrController < ApplicationController
  
  def get_images
    @settings = JSON.parse(params[:settings]) if params[:settings]
    user = flickr.people.findByUsername(:username => @settings["username"])
    @response = flickr.people.getPublicPhotos(:api_key => @settings["api_key"], :user_id => user.nsid)
    # puts("--------------------------------------------------")
    # puts(@response.inspect)
    # puts("--------------------------------------------------")

    respond_to do |format|
      format.html
    end
  end
  
end