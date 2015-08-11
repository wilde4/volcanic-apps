class JobBoardController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :new, :edit]

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


  protected
    def job_board_params
      params.require(:job_board).permit(:id, 
                                        :app_dataset_id, 
                                        :currency, 
                                        :charge_for_jobs,
                                        :job_token_price,
                                        :charge_for_cv_search,
                                        :cv_search_price,
                                        :cv_search_duration)
    end
  

end