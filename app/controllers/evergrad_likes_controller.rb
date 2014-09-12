class EvergradLikesController < ApplicationController
  protect_from_forgery with: :null_session
  require 'csv'
  respond_to :json, :csv

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  def save_user
    @user = LikesUser.find_by(user_id: params[:user][:id])
    if @user.present?
      @extra = {
        user_type: params[:user][:user_type],
        avatar_thumb_path: params[:user_profile][:avatar_thumb_path],
        avatar_medium_cropped_path: params[:user_profile][:avatar_medium_cropped_path],
        avatar_medium_uncropped_path: params[:user_profile][:avatar_medium_uncropped_path],
        avatar_large_cropped_path: params[:user_profile][:avatar_large_cropped_path],
        avatar_large_uncropped_path: params[:user_profile][:avatar_large_uncropped_path]
      }
      if @user.update(email: params[:user][:email], first_name: params[:user_profile][:first_name], last_name: params[:user_profile][:last_name], extra: @extra, registration_answers: params[:registration_answer_hash])
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = LikesUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]
      @user.first_name = params[:user_profile][:first_name]
      @user.last_name = params[:user_profile][:last_name]
      @extra = {
        user_type: params[:user][:user_type],
        avatar_thumb_path: params[:user_profile][:avatar_thumb_path],
        avatar_medium_cropped_path: params[:user_profile][:avatar_medium_cropped_path],
        avatar_medium_uncropped_path: params[:user_profile][:avatar_medium_uncropped_path],
        avatar_large_cropped_path: params[:user_profile][:avatar_large_cropped_path],
        avatar_large_uncropped_path: params[:user_profile][:avatar_large_uncropped_path]
      }
      @user.extra = @extra
      @user.registration_answers = params[:registration_answer_hash]

      if @user.save
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  def save_job
    @job = LikesJob.find_by(job_id: params[:job][:id])
    if @job.present?
      @extra = {
        job_type: params[:job_type],
        job_startdate: params[:job][:job_startdate],
        job_description: params[:job][:job_description],
        job_location: params[:job][:job_location],
        salary_free: params[:job][:salary_free],
        cached_slug: params[:job][:cached_slug]
      }
      if @job.update(
        job_reference: params[:job][:job_reference], 
        job_title: params[:job][:job_title], 
        expiry_date: params[:job][:expiry_date],
        extra: @extra
      )
        render json: { success: true, job_id: @job.id }
      else
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    else
      @job = LikesJob.new
      @job.job_id = params[:job][:id]
      @job.user_id = params[:job][:user_id]
      @job.expiry_date = params[:job][:expiry_date]
      @job.job_title = params[:job][:job_title]
      @job.job_reference = params[:job][:job_reference]
      @extra = {
        job_type: params[:job_type],
        job_startdate: params[:job][:job_startdate],
        job_description: params[:job][:job_description],
        job_location: params[:job][:job_location],
        salary_free: params[:job][:salary_free],
        cached_slug: params[:job][:cached_slug]
      }
      @job.extra = @extra

      if @job.save
        render json: { success: true, job_id: @job.id }
      else
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    end
  end

  def save_like
    @like = LikesLike.find_by(like_id: params[:like][:id])
    if @like.present?
      if @like.update(extra: params[:like][:extra])
        render json: { success: true, like_id: @like.id }
      else
        render json: { success: false, status: "Error: #{@like.errors.full_messages.join(', ')}" }
      end
    else
      @like = LikesLike.new
      @like.like_id = params[:like][:id]
      @like.user_id = params[:like][:user_id]
      @like.likeable_id = params[:like][:likeable_id]
      @like.likeable_type = params[:like][:likeable_type]
      @like.extra = params[:like][:extra]

      if @like.save
        # IS IT A MATCH?
        if @like.likeable_type == "Job"
          # GRADUATE HAS LIKED A JOB
          @job = LikesJob.find_by(job_id: @like.likeable_id)
          # NEED TO FIND IF GRADUATE HAS BEEN LIKED BY JOBS OWNER
          @matched_like = LikesLike.find_by(likeable_type: 'User', likeable_id: @like.user_id, user_id: @job.user_id)
          # MARK LIKE AND MATCHED LIKE AS MATCHED
          if @matched_like.present?
            # SEND MATCH EMAIL
            # curl -X POST -H "Content-Type: application/json" -d '{"api_key" : "b9461f78cb8b4ca70fbb369dc768f719", "event_name" : "match_made_by_graduate", "user_id" : "2659"}' http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json
            # @response = HTTParty.post('http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json', {:body => {event_name: 'match_made_by_graduate', user_id: @job.user_id}, :headers => { 'Content-Type' => 'application/json' }})
            @response = HTTParty.post('http://evergrad.staging.volcanic.uk/api/v1/event_services.json', {:body => {event_name: 'match_made_by_graduate', user_id: @job.user_id}, :headers => { 'Content-Type' => 'application/json' }})
            @matched_like.update(match: true) 
            @like.update(match: true) 
          end
        elsif @like.likeable_type == "User"
          # EMPLOYER HAS LIKED A GRADUATE
          @graduate = LikesUser.find_by(user_id: @like.likeable_id)
          # NEED TO SEE IF GRADUATE HAS LIKED ANY OF THE EMPLOYERS JOBS
          @job_ids = LikesJob.where(user_id: @like.user_id).map(&:job_id)
          @matched_likes = LikesLike.where(likeable_type: 'Job', likeable_id: @job_ids, user_id: @graduate.user_id)
          # MARK LIKE AND MATCHED LIKES AS MATCHED
          if @matched_likes.present?
            # SEND MATCH EMAIL
            # curl -X POST -H "Content-Type: application/json" -d '{"api_key" : "b9461f78cb8b4ca70fbb369dc768f719", "event_name" : "match_made_by_employer", "user_id" : "21125"}' http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json
            # @response = HTTParty.post('http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json', {:body => {event_name: 'match_made_by_employer', user_id: @graduate.user_id}, :headers => { 'Content-Type' => 'application/json' }})
            @response = HTTParty.post('http://evergrad.staging.volcanic.uk/api/v1/event_services.json', {:body => {event_name: 'match_made_by_employer', user_id: @graduate.user_id}, :headers => { 'Content-Type' => 'application/json' }})
            @matched_likes.update_all(match: true)
            @like.update(match: true) 
          end
        end

        render json: { success: true, like_id: @like.id }
      else
        render json: { success: false, status: "Error: #{@like.errors.full_messages.join(', ')}" }
      end
    end
  end

  def likes_made
    @likes = LikesLike.where(user_id: params[:id], match: false)
    @likes.delete_if { |l| l.likeable_type == 'User' and LikesUser.find_by(user_id: l.likeable_id).blank? }
    # REMOVE JOB IF IT HAS EXPIRED
    @likes.delete_if { |l| l.likeable_type == 'Job' and LikesJob.live.find_by(job_id: l.likeable_id).blank? }
    render layout: false
  end

  def likes_received
    @user = LikesUser.find_by(user_id: params[:id])
    if @user.extra["user_type"] == 'graduate'
      @likes = LikesLike.where(likeable_type: 'User', likeable_id: @user.user_id, match: false)
    elsif @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
      @jobs = LikesJob.where(user_id: @user.user_id).live
    end
    render layout: false
  end

  def matches
    @user = LikesUser.find_by(user_id: params[:id])
    if @user.extra["user_type"] == 'graduate'
      @matches = LikesLike.where(user_id: @user.user_id, match: true)

      # REMOVE JOB IF IT HAS EXPIRED, UNLESS REQUESTED
      if params[:include_expired] == false
        @matches.delete_if { |l| l.likeable_type == 'Job' and LikesJob.live.find_by(job_id: l.likeable_id).blank? }
      end

    elsif @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
      @job_ids = LikesJob.where(user_id: @user.user_id).live.map(&:job_id)
      @matches = LikesLike.where(likeable_type: 'Job', likeable_id: @job_ids, match: true)
      @jobs = LikesJob.where(user_id: @user.user_id).live
    end
    render layout: false
  end

  def all_matches
    @match_count = LikesLike.where(likeable_type: 'User', match: true).count
    render json: { match_count: @match_count }
  end

  def notification_events
    render json: {
      match_made_by_graduate: {
        description: 'A graduate creates a match',
        targets: [:user, :custom, :admin],
        tags: [:name, :email, :time]
      },
      match_made_by_employer: {
        description: 'An employer creates a match',
        targets: [:user, :custom, :admin],
        tags: [:name, :email, :time]
      }
    }
  end

  # GET /evergrad_likes/jobs_paid.json
  # Get the paid status for a job ID. Accepts a list of IDs for single lookups.
  # Returns array with ID and boolean
  def jobs_paid
    job_ids = params[:job_id].split(' ')
    jobs = LikesJob.where(job_id: job_ids)
    render json: { jobs: jobs.map{|j| [j.job_id, j.paid] } }
  end

  def index
    render layout: false
  end

  def overview
    start_date = (params[:data].present? and params[:data][:start_date].present?) ? Date.parse(params[:data][:start_date]) : Date.parse("2000-01-01")
    end_date = (params[:data].present? and params[:data][:end_date].present?) ? Date.parse(params[:data][:end_date]) : Date.parse("2050-01-01")

    employers = LikesUser.where("extra like ?", "%employer%")
    match_data = {}

    employers.each do |employer|
      employer_job_ids = LikesJob.where(user_id: employer.user_id).live.map(&:job_id)
      job_matches = LikesLike.where(likeable_type: 'User', likable_id: employer_job_ids, match: true)
      match_data[employer.user_id] = job_matches
    end

    byebug

    
    respond_to do |format|
      format.html {
        @matches = match_data
        render action: 'overview', layout: false
      }
      format.json { render json: {
          success: true, length: match_data.count, referrals: match_data
        }
      }
    end
  end

  def likes_csv
    @likes = LikesLike.where(likeable_type: 'Job')
    respond_to do |format|
      format.csv { send_data @likes.to_csv }
    end
  end


end