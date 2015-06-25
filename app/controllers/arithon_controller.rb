class ArithonController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    # @auth_url = YuTalent::AuthenticationService.auth_url(@app_id, @host)
    @settings = ArithonAppSetting.new #find_by(dataset_id: params[:data][:dataset_id])
  end

end