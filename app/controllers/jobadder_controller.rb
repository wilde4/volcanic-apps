class JobadderController < ApplicationController
  
    
  protect_from_forgery with: :null_session
  respond_to :xml

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]
  # before_action :set_xml, :check_api_access

  def index
    # @host = @key.host
    # @app_id = params[:data][:id]
    # render layout: false
    @ja_setting =  JobadderAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || JobadderAppSetting.new(dataset_id: params[:data][:dataset_id])


  end

  def update_ja_settings

    @key = Key.find_by(app_dataset_id: params[:jobadder_app_setting][:dataset_id], app_name: params[:controller])
    @jobadder_setting = JobadderAppSetting.find_by(dataset_id: params[:jobadder_app_setting][:dataset_id])

    if @jobadder_setting.present? #UPDATE CURRENT SETTINGS

      if @jobadder_setting.update(ja_params)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert] = "Settings could not be saved. Please try again."
      end

    else #CREATE NEW SETTINGS

      @jobadder_setting = JobadderAppSetting.new(ja_params)

      if @jobadder_setting.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end

    end


  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@ja_setting, @key, 'update_ja_settings', nil, nil, e.message, true, true)
  end

  private

    def ja_params
      params.require(:jobadder_app_setting).permit(
          :dataset_id,
          :import_jobs,
          :ja_params,
          :ja_username,
          :ja_password,
          :ja_client_id,
          :ja_client_secret
      )
    end


    def check_api_access
      head :unauthorized unless @key.present?
    end


end
  