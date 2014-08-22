class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  require "rubygems"
  require "net/https"
  require "uri"
  require 'json'
  require 'mandrill' 
  
end
