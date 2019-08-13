class V10SyncController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_filter :set_key, only: [:index, :save_job, :set_featured]

  def index
    @v10_sync_setting = V10SyncSetting.find_by(dataset_id: params[:data][:dataset_id]) || V10SyncSetting.new(dataset_id: params[:data][:dataset_id])


    render layout: false
  end

  def update

    @v10_sync_setting = V10SyncSetting.find_by(dataset_id: params[:v10_sync_setting][:dataset_id]) || V10SyncSetting.new(dataset_id: params[:v10_sync_setting][:dataset_id])

    if @v10_sync_setting.update(params[:v10_sync_setting].permit!)
      flash[:notice]  = "Settings successfully saved."
    else
      flash[:alert] = "Settings could not be saved. Please try again."
    end
  end

  def jobs
    @v10_sync_setting = V10SyncSetting.find_by(dataset_id: params[:dataset_id])
    render json: { "error"=> "not configured" } and return if @v10_sync_setting.blank? || @v10_sync_setting.endpoint.blank? || @v10_sync_setting.api_key.blank?

    job = params[:job].except(:id, :job_type_id, :views, :retired, :retired_at, :keyword_cache, :salary_hidden, :benefits, :exclusive_until, :salary_currency, :salary_benefits, :user_id, :extra, :paid, :homepage, :image_uid, :image_name)

    discipline_string = params[:disciplines].map{|d| d[:reference]}.join(',')

    job[:job_type] = params[:job_type]
    job[:discipline] = discipline_string


    url = "#{@v10_sync_setting.endpoint}/api/v1/jobs.json"

    response = HTTParty.post(url, body: {job: job, api_key: @v10_sync_setting.api_key})

    if response.success?
      render json: { "success"=> "true" } and return
    else
      render json: { "error"=> "failed to post" } and return
    end
  end
end