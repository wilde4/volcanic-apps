class MercuryXrmController < ApplicationController
  protect_from_forgery with: :null_session
  layout "no_jquery_application"

  def index
    _ms = MercuryXrmSetting.find_by(dataset_id: params[:data][:dataset_id])
    @dataset_id = params[:data][:dataset_id]
    @mercury_xrm_url =    _ms.present? ? _ms.settings[:integration_url].to_s : "" 
    @mercury_xrm_key =    _ms.present? ? _ms.settings[:encryption_key].to_s : "" 
    @mercury_xrm_cipher = _ms.present? ? _ms.settings[:encryption_cipher].to_s : "" 
    render layout: false
  end

  def update
    _ms = MercuryXrmSetting.find_by(dataset_id: params[:mercury][:dataset_id])
    if _ms.present?
      _ms.settings[:integration_url] =    params[:mercury][:integration_url]
      _ms.settings[:encryption_key] =     params[:mercury][:encryption_key]
      _ms.settings[:encryption_cipher] =  params[:mercury][:encryption_cipher]
      _ms.save
    else
      _ms = MercuryXrmSetting.create(dataset_id: params[:mercury][:dataset_id], settings: {
        integration_url:    params[:mercury][:integration_url],
        encryption_key:     params[:mercury][:encryption_key],
        encryption_cipher:  params[:mercury][:encryption_cipher],
      })
    end
    render nothing: true, status: :success and return
  end

  def mercury_xrm_dashboard
    @encrypted_email = encrypt_email(params[:data][:dataset_id], params[:data][:email])
    @encrypted_email.gsub!("\n", '')
    @mercury_url = MercuryXrmSetting.find_by(dataset_id: params[:data][:dataset_id]).settings[:integration_url] rescue ""
    render "mercury_xrm_dashboard"
  end

  private

  def encrypt_email(dataset_id, email)
    return "" if dataset_id.blank?
    return "" if email.blank?

    _ms = MercuryXrmSetting.find_by(dataset_id: dataset_id)
    return "" if _ms.nil?
    [:integration_url, :encryption_key, :encryption_cipher].each do |_k|
      return "" if _ms.settings[_k].blank?
    end
    _k = "12FAECC2BF96963967CF77BD8BB117B1B184BB0BDC1E746B0D1FE8A160623A4E"
    _c = "1F3B7D1F98CCF4A240FBAB3F0466E4F1"

    # Pull in the values we need here...
    # return AesEncryptionService.encrypt_email(email, _ms.settings[:encryption_key], _ms.settings[:encryption_cipher])
    return AesEncryptionService.encrypt_email(email, _k, _c)
  end

  # user dashboard, checks to see if the Mercury XRM App is enabled
  # if yes: then calls the insert_hooks helper
  # which constructs a HTTP GET request to Volcanic Apps server, passing the current_users email
  # once VA receives this request: then it performs some logic
  # and renders/returns a view which is then displayed on the user dashboard
end


# https://red-portals.azurewebsites.net/mercury.candidateportal/app/portalwidget.js
# 12FAECC2BF96963967CF77BD8BB117B1B184BB0BDC1E746B0D1FE8A160623A4E
# 1F3B7D1F98CCF4A240FBAB3F0466E4F1