class YoutubeController < ApplicationController
  require 'youtube_it'
  
  def related_videos
    @settings = JSON.parse(params[:settings]) if params[:settings]
    client = YouTubeIt::Client.new(:dev_key => @settings["key"])
    @response = client.videos_by(:user => @settings["user_id"])
    
    respond_to do |format|
      format.html
    end
  end

end