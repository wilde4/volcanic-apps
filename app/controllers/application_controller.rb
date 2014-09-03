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

  # Use the app server suitable for the host environment
  def app_server_host
    if Rails.env.development?
      "localhost:3001"
    elsif Rails.env.production?
      "apps.volcanic.co"
    end
  end

  def activate_app
    key = Key.new
    key.host = params[:data][:host]
    key.dataset_id = params[:data][:dataset_id]
    key.api_key = params[:data][:api_key]
    key.app_name = params[:controller]

    respond_to do |format|
        format.json { render json: { success: key.save }}
    end
  end

  def deactivate_app
    key = Key.where(dataset_id: params[:data][:dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        format.json { render json: { success: key.destroy }}
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end

  
end
