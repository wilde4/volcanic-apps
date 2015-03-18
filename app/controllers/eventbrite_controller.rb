class EventbriteController < ApplicationController

  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :update_eventbrite_settings]


  def index
    @dataset_id = @key.app_dataset_id
    @host = app_server_host + "/eventbrite/update_eventbrite_settings"
    @settings = EventbriteSetting.find_by(dataset_id: @dataset_id)
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
    query, dataset_id = params[:query], params[:dataset_id]
    @results = Eventbrite::EventsService.search(dataset_id, query) if query and dataset_id
    if @results
      render json: @results, status: 200
    else
      render json: @results.errors, status: :unprocessable_entity
    end
  end


  def import
    event_id, dataset_id = params[:event_id], params[:dataset_id]
    @event = Eventbrite::EventsService.import_event(dataset_id, event_id) if event_id and dataset_id
    if @event
      render json: @event, status: 200
    else
      render json: { message: "Could not find event!" , status: :unprocessable_entity }
    end
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
