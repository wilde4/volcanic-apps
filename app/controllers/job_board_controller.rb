class JobBoardController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :new, :edit, :purchasable, :require_tokens_for_jobs, :access_for_cv_search, :increase_cv_access_time, :client_form, :client_create, :user_form, :user_update]
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
      
      purchasable[:job_token] = { price: @job_board.job_token_price, duration: @job_board.job_duration, title: @job_board.job_token_title, description: @job_board.job_token_description } if @job_board.charge_for_jobs

      purchasable[:cv_search] = { price: @job_board.cv_search_price, duration: @job_board.cv_search_duration, title: @job_board.cv_search_title, description: @job_board.cv_search_description } if @job_board.charge_for_cv_search

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
        if params[:data][:client_token].present?
          most_recent = CvSearchAccessDuration.where(client_token: params[:data][:client_token], app_dataset_id: @key.app_dataset_id).last
        else
          most_recent = CvSearchAccessDuration.where(user_token: params[:data][:user_token], app_dataset_id: @key.app_dataset_id).last
        end        
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
    if params[:data][:client_token].present?
      most_recent = CvSearchAccessDuration.where(client_token: params[:data][:client_token], app_dataset_id: @key.app_dataset_id).last
    else
      most_recent = CvSearchAccessDuration.where(user_token: params[:data][:user_token], app_dataset_id: @key.app_dataset_id).last
    end

    duration = params[:data][:duration].to_i

    if most_recent.present? && most_recent.expiry_date > Time.now
      most_recent_expiry = most_recent.expiry_date
    else
      most_recent_expiry = Time.now
    end

    cv_search = CvSearchAccessDuration.new
    cv_search.duration_added = duration * @job_board.cv_search_duration
    cv_search.expiry_date    = most_recent_expiry + cv_search.duration_added.days
    cv_search.user_token     = params[:data][:user_token]
    cv_search.client_token   = params[:data][:client_token]
    cv_search.app_dataset_id = @key.app_dataset_id

    if cv_search.save
      render json: { success: true, expiry_date: cv_search.expiry_date }
      return
    else
      render json: { success: false }
      return
    end
  end

  def client_form
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
    @latest = CvSearchAccessDuration.where(client_token: params[:data][:client_token], app_dataset_id: @key.app_dataset_id).last
  end

  def client_create
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)

    if params[:client][:extra].present?
      extra = params[:client][:extra]
      if extra[:cv_search].present? && extra[:cv_search][:duration].present?
        most_recent = CvSearchAccessDuration.where(client_token: params[:client][:secure_random], app_dataset_id: @key.app_dataset_id).last
        duration = extra[:cv_search][:duration].to_i

        if most_recent.present? && most_recent.expiry_date > Time.now
          most_recent_expiry = most_recent.expiry_date
        else
          most_recent_expiry = Time.now
        end

        cv_search = CvSearchAccessDuration.new
        cv_search.duration_added = duration * @job_board.cv_search_duration
        cv_search.expiry_date    = most_recent_expiry + cv_search.duration_added.days
        cv_search.client_token   = params[:client][:secure_random]
        cv_search.app_dataset_id = @key.app_dataset_id

        cv_search.save
      end
    end

    render nothing: true, status: 200 and return
  end

  def user_form
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)
    @latest = CvSearchAccessDuration.where(user_token: params[:data][:user_token], app_dataset_id: @key.app_dataset_id).last
  end

  def user_update
    @job_board = JobBoard.find_by(app_dataset_id: @key.app_dataset_id)

    if params[:user][:extra].present?
      extra = params[:user][:extra]
      if extra[:cv_search].present? && extra[:cv_search][:duration].present?
        most_recent = CvSearchAccessDuration.where(user_token: params[:user][:secure_random], app_dataset_id: @key.app_dataset_id).last
        duration = extra[:cv_search][:duration].to_i

        if most_recent.present? && most_recent.expiry_date > Time.now
          most_recent_expiry = most_recent.expiry_date
        else
          most_recent_expiry = Time.now
        end

        cv_search = CvSearchAccessDuration.new
        cv_search.duration_added = duration * @job_board.cv_search_duration
        cv_search.expiry_date    = most_recent_expiry + cv_search.duration_added.days
        cv_search.user_token   = params[:user][:secure_random]
        cv_search.app_dataset_id = @key.app_dataset_id

        cv_search.save
      end
    end

    render nothing: true, status: 200 and return
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
                                        :require_access_for_cv_search,
                                        :job_duration,
                                        :job_token_title,
                                        :job_token_description,
                                        :cv_search_title,
                                        :cv_search_description)
    end

    def authorise_key
      render nothing: true, status: 401 and return unless @key.api_key == params[:apikey]
    end
  

end