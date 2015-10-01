class EclipseCrmController < ApplicationController
  protect_from_forgery with: :null_session
  
  before_filter :set_key, only: [:index]

  def index
    @host = @key.host
  end

end