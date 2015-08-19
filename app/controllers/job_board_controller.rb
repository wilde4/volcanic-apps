class JobBoardController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :new, :edit, :purchasable, :require_tokens_for_jobs, :access_for_cv_search, :increase_cv_access_time]
  before_action :authorise_key, only: [:purchasable, :require_tokens_for_jobs, :access_for_cv_search, :increase_cv_access_time] #requires set_key to have executed first

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
  end

  def new
    @job_board = JobBoard.new
    @job_board.app_dataset_id = @key.app_dataset_id
  end

  def create
    @job_board = JobBoard.new(job_board_params)

    respond_to do |format|
      if @job_board.save
        format.html { render action: 'index' }
        format.json { render json: { success: true, job_board: @job_board }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@job_board.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def edit
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
  end

  def update
    @job_board = JobBoard.find_by(params[:job_board][:id])
    
    respond_to do |format|
      if @job_board.update_attributes(job_board_params)
        format.html { render action: 'index' }
        format.json { render json: { success: true, job_board: @job_board }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@job_board.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def purchasable
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
    
    if @job_board.present?
      purchasable = {}
      
      purchasable[:job_token] = { price: @job_board.job_token_price } if @job_board.charge_for_jobs

      purchasable[:cv_search] = { price: @job_board.cv_search_price, duration: @job_board.cv_search_duration } if @job_board.charge_for_cv_search

      purchasable[:currency] = @job_board.currency

      render json: { success: true, purchasable: purchasable }
    else
      render json: { success: false }
    end
  end

  def require_tokens_for_jobs
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
    if @job_board.present?
      if @job_board.require_tokens_for_jobs
        render json: { success: true, tokens: true }
        return
      else
        render json: { success: true, tokens: false }
        return
      end
    else
      render json: { success: false }
      return
    end
  end

  def access_for_cv_search
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
    if @job_board.present?
      if @job_board.require_access_for_cv_search
        most_recent = CvSearchAccessDuration.where(user_token: params[:data][:user_token], app_dataset_id: @key.app_dataset_id).last
        if most_recent.present? && most_recent.expiry_date > Time.now
          render json: { success: true, access: true, expiry_date: most_recent.expiry_date }
          return
        else
          render json: { success: true, access: false }
          return
        end
      else
        render json: { success: true, access: true }
        return
      end
    else
      render json: { success: false }
      return
    end
  end

  def increase_cv_access_time
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
    most_recent = CvSearchAccessDuration.where(user_token: params[:data][:user_token], app_dataset_id: @key.app_dataset_id).last
    duration = params[:data][:duration].to_i

    if most_recent.present? && most_recent.expiry_date > Time.now
      most_recent_expiry = most_recent.expiry_date
    else
      most_recent_expiry = Time.now
    end

    cv_search = CvSearchAccessDuration.new
    cv_search.duration_added = duration
    cv_search.expiry_date    = most_recent_expiry + duration.days
    cv_search.user_token     = params[:data][:user_token]
    cv_search.app_dataset_id = @key.app_dataset_id

    if cv_search.save
      render json: { success: true, expiry: cv_search.expiry_date }
      return
    else
      render json: { success: false }
      return
    end
  end



  protected
    def job_board_params
      params.require(:job_board).permit(:id, 
                                        :app_dataset_id, 
                                        :currency, 
                                        :charge_for_jobs,
                                        :job_token_price,
                                        :charge_for_cv_search,
                                        :cv_search_price,
                                        :cv_search_duration,
                                        :require_tokens_for_jobs,
                                        :require_access_for_cv_search)
    end

    def authorise_key
      render nothing: true, status: 401 and return unless @key.api_key == params[:apikey]
    end
  

end