class EtzController < ApplicationController
  protect_from_forgery with: :null_session
  after_filter :setup_access_control_origin

  def index
    @setting = EtzSetting.find_by dataset_id: params[:data][:dataset_id]
    create_settings if @setting.blank?

    render layout: false
  end

  def show
    @setting = EtzSetting.find_by dataset_id: params[:data][:dataset_id]
    render json: { url: @setting.try(:url) }
  end

  def update
    @setting = EtzSetting.find_by dataset_id: params[:etz_setting][:dataset_id]

    if @setting.update(params[:etz_setting].permit!)
      flash[:notice] = "Settings successfully saved."
    else
      flash[:alert] = "Settings could not be saved. Please try again."
    end
  end

  private

  def create_settings
    EtzSetting.create(dataset_id: params[:data][:dataset_id])
  end

end
