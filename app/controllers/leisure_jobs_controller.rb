class LeisureJobsController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  # after_filter :setup_access_control_origin

  before_filter :set_key, only: [:index]

  def index
    @host = @key.host
  end

end
