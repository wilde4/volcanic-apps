class FeaturedJobsController < ApplicationController 
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_filter :set_key, only: [:save_job, :set_featured]

  def save_job
    @job = FeaturedJob.find_by(job_id: params[:job][:id])
    if @job.present?
      if @job.update(
        job_reference: params[:job][:job_reference], 
        job_title: params[:job][:job_title], 
        extra: {
          job_type: params[:job_type],
          job_startdate: params[:job][:job_startdate],
          job_description: params[:job][:job_description],
          job_location: params[:job][:job_location],
          salary_free: params[:job][:salary_free],
          cached_slug: params[:job][:cached_slug]
        }
      )
        render json: { success: true, job_id: @job.id }
      else
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    else
      @job = FeaturedJob.new
      @job.job_id = params[:job][:id]
      @job.user_id = params[:job][:user_id]
      @job.dataset_id = @key.app_dataset_id
      @job.job_title = params[:job][:job_title]
      @job.job_reference = params[:job][:job_reference]
      @job.extra = {
        job_type: params[:job_type],
        job_startdate: params[:job][:job_startdate],
        job_description: params[:job][:job_description],
        job_location: params[:job][:job_location],
        salary_free: params[:job][:salary_free],
        cached_slug: params[:job][:cached_slug]
      }

      if @job.save
        render json: { success: true, job_id: @job.id }
      else
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    end
  end

  def featured
    @featured = FeaturedJob.featured
    render json: @featured.as_json
  end

  def set_featured
    render nothing: true, status: 400 and return if params[:job].blank?

    error_message = ""

    # Check we've got the right conditions for setting:
    if params[:job][:job_id].blank?
      error_message << "Job ID cannot be blank!"
    elsif params[:job][:days_active].blank?
      error_message << "A number of days must be given!"
    end

    days_active = params[:job][:days_active].to_i
    job = FeaturedJob.find(params[:job][:job_id])

    # Halt here if there's errors in the process:
    if job.blank?
      render json: { success: false, error: "Cannot find Job ID #{params[:job][:job_id]}." }
    elsif error_message.present?
      render json: { success: false, error: error_message }
    end

    job.feature_start = FeaturedJob.next_available_date(@key.app_dataset_id)
    job.feature_end = job.feature_start + days_active.days
    
    respond_to do |format|
      if job.save
        format.json { render json: { success: true, message: "Successfully saved Job." }}
      else
        format.json { render json: { success: false, error: job.errors }}
      end
    end
  end

private

  def set_key
    @key = Key.find_by(host: params[:referrer])
    render nothing: true, status: 401 and return if @key.blank?
  end

end