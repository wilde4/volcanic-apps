class EventbriteController < ApplicationController

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :update_eventbrite_settings]


  def index
    @dataset_id = @key.app_dataset_id
    @host = app_server_host + "/eventbrite/update_eventbrite_settings"
    @settings = EventbriteSetting.find_by(dataset_id: @dataset_id)

    puts "hit index  ===== #{params}"
  end


  def update_eventbrite_settings
    @settings = EventbriteSetting.find_by(dataset_id: params[:data][:dataset_id])
    if @settings.present?
      if @settings.update(
        dataset_id: params[:data][:dataset_id],
        app_key: params[:data][:app_key],
        user_key: params[:data][:user_key]
      )
        flash[:notice] = "Settings Saved Successfully"
      else
        flash[:alert] = "Settings not saved"
      end
    else
      @settings = EventbriteSetting.new
      @settings[:dataset_id] = params[:data][:dataset_id]
      @settings[:app_key] = params[:data][:app_key]
      @settings[:user_key] = params[:data][:user_key]

      if @settings.save
        flash[:notice] = "Settings Saved Successfully"
      else
        flash[:alert] = "Settings not saved"
      end
    end
  end


  def search
    query = params[:query]
    results = Eventbrite::EventsService.new(@dataset_id).search(query) if query
  end


  def import
    event_id = params[:event_id]
    results = Eventbrite::EventsService.new(@dataset_id).import_event(event_id) if event_id
  end


  private

    def set_dataset_id
      @dataset_id = @key.app_dataset_id
    end


    def app_server_host
      if Rails.env.development?
        "http://localhost:3001"
      elsif Rails.env.production?
        "apps.volcanic.co"
      end
    end


end
