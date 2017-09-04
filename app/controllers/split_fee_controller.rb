class SplitFeeController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :edit, :job_form, :job_create, :shared_candidate_form]

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
    render layout: false
  end

  def edit
    @split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: @key.app_dataset_id)
    render layout: false
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

  def job_form
    @split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: @key.app_dataset_id)
    @job = JSON.parse(params[:data][:job])
    render layout: false
  end

  def job_create

    job_id = params[:job][:id]
    
    if params[:job][:extra].present? && params[:job][:extra][:split_fee].present?
      
      split_free_params = params[:job][:extra][:split_fee]
      split_fee =         SplitFee.find_by(job_id: job_id)
      salary_band =       params[:job][:salary_high]
      
      if split_fee.present?
        split_fee.update_attributes(job_id: job_id,
                        app_dataset_id: @key.app_dataset_id,
                        salary_band: salary_band,
                        fee_percentage: split_free_params[:fee_percentage],
                        terms_of_fee: split_free_params[:terms_of_fee],
                        expiry_date: params[:job][:expiry_date])
      else
        SplitFee.create(job_id: job_id,
                        app_dataset_id: @key.app_dataset_id,
                        salary_band: salary_band,
                        fee_percentage: split_free_params[:fee_percentage],
                        terms_of_fee: split_free_params[:terms_of_fee],
                        expiry_date: params[:job][:expiry_date])
      end
    end

    render nothing: true, status: 200 and return
  end

  def job_expire
    job_id = params[:job][:id]
    split_fee = SplitFee.find_by(job_id: job_id)
    if split_fee.present?
      split_fee.update_attributes(expiry_date: Date.yesterday)
    end
    render nothing: true, status: 200 and return
  end

  def job_destroy
    job_id = params[:job][:id]
    split_fee = SplitFee.find_by(job_id: job_id)
    if split_fee.present?
      split_fee.update_attributes(expiry_date: Date.yesterday)
    end
    render nothing: true, status: 200 and return
  end

  def current_split_fee
    value = SplitFee.where(app_dataset_id: params[:dataset_id]).where("expiry_date >= ?", Time.now).sum(:split_fee_value)
    respond_to do |format|
      format.json { render json: { success: true, total: value } }
    end
  end

  def get_split_fee
    fee = SplitFee.where(app_dataset_id: params[:dataset_id], job_id: params[:job_id]).last
    respond_to do |format|
      format.json { render json: { success: true, split_fee: fee } }
    end
  end

  def get_shared_candidate_split_fee

    fee = SplitFee.where(app_dataset_id: params[:dataset_id], user_id: params[:user_id]).last

    respond_to do |format|
      format.json { render json: { success: true, split_fee: fee } }
    end
  end




  def shared_candidate_form
    @split_fee_setting = SplitFeeSetting.find_by(app_dataset_id: @key.app_dataset_id)
    @user = get_shared_canddiate( JSON.parse(params["data"]["user"])["id"] )
    render layout: false
  end

  def shared_candidate_create

    u = get_shared_canddiate(params[:user][:id])

    _salary_band =    params[:user][:salary_high]
    _fee_percentage = 12.5
    _expiry_date =    Date.today + 1.year

    if u.nil?
      SplitFee.create(
        user_id:         params[:user][:id].to_i,
        app_dataset_id:  params[:apikey][:dataset_id],
        salary_band:     _salary_band,
        fee_percentage:  _fee_percentage.to_i,
        terms_of_fee:    params[:user][:split_fee][:terms_of_fee],
        expiry_date:     _expiry_date
      )
    else
      u.update_attributes(
        user_id:         params[:user][:id].to_i,
        app_dataset_id:  params[:apikey][:dataset_id],
        salary_band:     _salary_band,
        fee_percentage:  _fee_percentage.to_i,
        terms_of_fee:    params[:user][:split_fee][:terms_of_fee],
        expiry_date:     _expiry_date
      )
    end

    render nothing: true, status: 200 and return
  end

  def shared_candidate_destroy
    
    u = get_shared_canddiate(params[:user][:id])

    if !u.nil?
      u.update_attributes(expiry_date: Date.yesterday)
    end

    render nothing: true, status: 200 and return
  end

  protected

  def get_shared_canddiate(user_id)

    return (user_id.nil? ? SplitFee.new : SplitFee.find_by(user_id: user_id))
  end

  def split_fee_setting_params
    
    params.require(:split_fee_setting).permit(:app_dataset_id, :salary_bands, :details)
  end
end
