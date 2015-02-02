class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  require "rubygems"
  require "net/https"
  require "uri"
  require 'json'
  require 'mandrill'

  # Allow sites to perform POST with XmlHttpRequest to the app server
  # Use 'after_filter' to access this
  # Development should point to http://<site>.localhost.volcanic.co:3000
  # Production should point to the volcanic apps server
  def setup_access_control_origin
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def activate_app
    key = Key.new
    key.host = params[:data][:host]
    key.app_dataset_id = params[:data][:app_dataset_id]
    key.api_key = params[:data][:api_key]
    key.app_name = params[:controller]

    respond_to do |format|
        format.json { render json: { success: key.save }}
    end
  end

  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        format.json { render json: { success: key.destroy }}
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end

  def update_settings
    settings = AppSetting.find_by(dataset_id: params[:dataset_id])

    if settings.present?
      settings.update(settings: params[:settings])
    else
      settings = AppSetting.create(dataset_id: params[:dataset_id], settings: params[:settings])
    end

    respond_to do |format|
      if settings.errors.blank?
        format.json { render json: { success: true, message: 'Updated App Settings.' }}
      else
        format.json { render json: { success: false, error: settings.errors } }
      end
    end
  end

protected

  def set_key
    if params[:data].present?
      app_dataset_id = params[:data][:dataset_id]
    elsif params[:dataset_id].present?
      app_dataset_id = params[:dataset_id]
    elsif params[:like].present?
      app_dataset_id = params[:like][:dataset_id]
    elsif params[:user].present?
      app_dataset_id = params[:user][:dataset_id]
    end

    @key = Key.find_by(app_dataset_id: app_dataset_id, app_name: params[:controller])
    render nothing: true, status: 401 and return if @key.blank?
  end

end
