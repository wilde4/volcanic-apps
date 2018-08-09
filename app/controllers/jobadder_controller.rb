class JobadderController < ApplicationController
  
  protect_from_forgery with: :null_session , except: [:save_settings]
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index

    @key = Key.find_by app_dataset_id: params[:data][:dataset_id], app_name: params[:controller]
    @ja_setting =  JobadderAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || JobadderAppSetting.new(dataset_id: params[:data][:dataset_id])

    @ja_service = Jobadder::ClientService.new(@ja_setting, 'http://127.0.0.1:3001/jobadder/callback') if @ja_setting.present?

    # if @ja_service.present? && @ja_service.client_authenticated?
    #   get_fields
    # end


    render layout: false

  end

  def callback
    @attributes                       = Hash.new
    @attributes[:authorization_code]  = params[:code]
    @attributes[:access_token]        = Jobadder::AuthenticationService.get_access_token(params[:code], @@client)



  end

  def update

    @key = Key.find_by(app_dataset_id: params[:jobadder_app_setting][:dataset_id], app_name: params[:controller])
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:jobadder_app_setting][:dataset_id])

    if @ja_setting.present? #UPDATE CURRENT SETTINGS

      if @ja_setting.update(ja_params)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert] = "Settings could not be saved. Please try again."
      end

    else #CREATE NEW SETTINGS

      @ja_setting = JobadderAppSetting.new(ja_params)

      if @ja_setting.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end

    end


    @ja_service = Jobadder::ClientService.new(@ja_setting, 'http://127.0.0.1:3001/jobadder/callback');
    render :js => "window.open('#{@ja_service.authorize_url}', 'authPopup', 'menubar=no,toolbar=no,status=no,width=400,height=400,left=400,top=400')"



    # @ja_setting.update_attribute(:authorised, true)

  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@ja_setting, @key, 'update_ja_settings', nil, nil, e.message, true, true)
  end

  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        ja_setting = JobadderAppSetting.find_by(dataset_id: params[:data][:app_dataset_id])
        ja_setting.destroy if ja_setting
        format.json { render json: { success: key.destroy }}
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end

  # def setup_client
  #
  #   @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || JobadderAppSetting.find_by(dataset_id: params[:jobadder_app_setting][:dataset_id])
  #   @@client = Jobadder::AuthenticationService.client(@ja_setting)
  #   @authorize_url = Jobadder::AuthenticationService.authorize_url('http://127.0.0.1:3001/jobadder/callback', @@client)
  #
  # end


  private

    def popup_window_size
       @window_features = 'menubar=no,toolbar=no,status=no,width=400,height=400,left=400,top=400'
    end

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
  