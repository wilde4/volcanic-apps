class ZapierController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_filter :set_key, only: [:index]

  def index
    render layout: false
  end

end