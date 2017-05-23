class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :job_application, :save_user, :upload_cv, :new_search, :jobs]

  # To Authorize a Bullhorn API user, follow instruction on https://github.com/bobop/bullhorn-rest
  def index
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || BullhornAppSetting.new(dataset_id: params[:data][:dataset_id])


    render layout: false
  end


  def update
    @key = Key.find_by(app_dataset_id: params[:bullhorn_app_setting][:dataset_id], app_name: params[:controller])
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:bullhorn_app_setting][:dataset_id])


    if @bullhorn_setting.present? #UPDATE CURRENT SETTINGS

      if @bullhorn_setting.update(bh_params)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert] = "Settings could not be saved. Please try again."
      end

    else #CREATE NEW SETTINGs

      @bullhorn_setting = BullhornAppSetting.new(bh_params)

      if @bullhorn_setting.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end

    end

    @bullhorn_setting.update_authorised_settings


  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'update', nil, nil, e.message, true, true)
  end


  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:data][:app_dataset_id])
        bullhorn_setting.destroy if bullhorn_setting
        format.json { render json: { success: key.destroy }}
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end



  private

    def bh_params
      params.require(:bullhorn_app_setting).permit(:dataset_id, :import_jobs, :linkedin_bullhorn_field, :source_text,
        :always_create, :cv_type_text, :uses_public_filter, :bh_params, :bh_username, :bh_password, :bh_client_id, :bh_client_secret, :bullhorn_field_mappings)
    end

end