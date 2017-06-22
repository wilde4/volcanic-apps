class AppLogsController < ApplicationController

  respond_to :json

  def index
    key = Key.find_by api_key: params[:api_key]
    if key.present?
      respond_with key.app_logs
    else
      render json: {}, status: :unauthorised
    end
  end
end