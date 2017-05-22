class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  # Controller requires cross-domain POST XHRs

  # To Authorize a Bullhorn API user, follow instruction on https://github.com/bobop/bullhorn-rest
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

  def index
    render layout: false
  end


end