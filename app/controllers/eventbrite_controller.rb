class EventbriteController < ApplicationController

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :update_eventbrite_settings]


  def index
    @dataset_id = @key.app_dataset_id
    @host = app_server_host + "/eventbrite/update_eventbrite_settings"
    @settings = EventbriteSetting.find_by(dataset_id: @dataset_id)
    render layout: false
  end

  def edit
  end

  def update_eventbrite_settings
    @settings = EventbriteSetting.find_by(dataset_id: params[:data][:dataset_id])
    if @settings.present?
      if @settings.update(
        dataset_id: params[:data][:dataset_id],
        access_token: params[:data][:access_token]
      )
        flash[:notice] = "Settings Saved Successfully"
      else
        flash[:alert] = "Settings not saved"
      end
    else
      @settings = EventbriteSetting.new
      @settings[:dataset_id] = params[:data][:dataset_id]
      @settings[:access_token] = params[:data][:access_token]

      if @settings.save
        flash[:notice] = "Settings Saved Successfully"
      else
        flash[:alert] = "Settings not saved"
      end
    end
  end


  def search
    accesstoken = EventbriteSetting.find_by(dataset_id: params[:data][:dataset_id]).access_token
    
    if params[:eventbrite_page].present?
      # @responce = HTTParty.get("https://www.eventbriteapi.com/v3/events/search/?page=#{params[:eventbrite_page]}", headers: {"Authorization" => "Bearer #{accesstoken}"})
      @responce = HTTParty.get("https://www.eventbriteapi.com/v3/users/me/owned_events/?status=live&page=#{params[:eventbrite_page]}", headers: {"Authorization" => "Bearer #{accesstoken}"})
    else
      # @responce = HTTParty.get("https://www.eventbriteapi.com/v3/events/search/", headers: {"Authorization" => "Bearer #{accesstoken}"})
      @responce = HTTParty.get("https://www.eventbriteapi.com/v3/users/me/owned_events/?status=live", headers: {"Authorization" => "Bearer #{accesstoken}"}, verify: false)
    end
    if @responce.code == 200
      render json: @responce
    else
      render status: 401
    end  
  end


  def import
    accesstoken = EventbriteSetting.find_by(dataset_id: params[:data][:dataset_id]).access_token
    @responce = HTTParty.get("https://www.eventbriteapi.com/v3/events/#{params[:eventbrite_id]}", headers: {"Authorization" => "Bearer #{accesstoken}"})
    
    render json: @responce
  end


  private

    def set_dataset_id
      @dataset_id = @key.app_dataset_id
    end


    def app_server_host
      if Rails.env.development?
        "http://localhost:3001"
      else
        "https://apps.volcanic.co"
      end
    end


end