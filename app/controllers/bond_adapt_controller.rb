class BondAdaptController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
  end
  
  def save_user
    BondAdapt::ClientService.new(params[:dataset_id], params[:user_name], params[:user_email], parmas[:user_phone], params[:user_url]).send_to_bond_adapt('create_user')
  end
  
  private
  
    def user_exists?
      @user_exists_var ||= User.exists?(id: params[:user][:id])
    end
  
    def user
      @user_var ||= User.find_by(id: params[:user][:id])
    end
end