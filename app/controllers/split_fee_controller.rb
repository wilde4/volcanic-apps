class SplitFeeController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :edit]

  def activate_app
    key = Key.new
    key.host = params[:data][:host]
    key.app_dataset_id = params[:data][:app_dataset_id]
    key.api_key = params[:data][:api_key]
    key.app_name = params[:controller]

    existing_split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: params[:data][:app_dataset_id])
    unless existing_split_fee_setting.present?
      SplitFeeSetting.create(app_dataset_id: params[:data][:app_dataset_id])
    end

    respond_to do |format|
      format.json { render json: { success: key.save }}
    end
  end

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: @key.app_dataset_id)
  end

  def edit
    @split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: @key.app_dataset_id)
  end

  def update
    @split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: params[:split_fee_setting][:app_dataset_id])

    respond_to do |format|
      if @split_fee_setting.update_attributes(split_fee_setting_params)
        format.html { render action: 'index' }
        format.json { render json: { success: true, split_fee_setting: @split_fee_setting }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@split_fee_setting.errors.full_messages.join(', ')}"
        }}
      end
    end

  end


  protected
    def split_fee_setting_params
      params.require(:split_fee_setting).permit(:app_dataset_id, :salary_bands)
    end

  

end