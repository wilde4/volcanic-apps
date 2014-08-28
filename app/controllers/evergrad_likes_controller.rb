class EvergradLikesController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  def save_user
    @user = LikesUser.find_by(user_id: params[:user][:id])
    if @user.present?
      @extra = {
        user_type: params[:user][:user_type],
        avatar_path: params[:user_profile][:avatar_path]
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
        avatar_path: params[:user_profile][:avatar_path]
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
      if @job.update(job_reference: params[:job][:job_reference], job_title: params[:job][:job_title], cached_slug: params[:job][:cached_slug])
        render json: { success: true, job_id: @job.id }
      else
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    else
      @job = LikesJob.new
      @job.job_id = params[:job][:id]
      @job.user_id = params[:job][:user_id]
      @job.job_reference = params[:job][:job_reference]
      @job.job_title = params[:job][:job_title]
      @job.cached_slug = params[:job][:cached_slug]

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
            @response = HTTParty.post('http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json', {:body => {event_name: 'match_made_by_graduate', user_id: @job.user_id}, :headers => { 'Content-Type' => 'application/json' }})
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
            @response = HTTParty.post('http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json', {:body => {event_name: 'match_made_by_employer', user_id: @graduate.user_id}, :headers => { 'Content-Type' => 'application/json' }})
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
    render layout: false
  end

  def likes_received
    @user = LikesUser.find_by(user_id: params[:id])
    if @user.extra["user_type"] == 'graduate'
      @likes = LikesLike.where(likeable_type: 'User', likeable_id: @user.user_id, match: false)
    elsif @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
      @job_ids = LikesJob.where(user_id: @user.user_id).map(&:job_id)
      @likes = LikesLike.where(likeable_type: 'Job', likeable_id: @job_ids, match: false)
    end
    render layout: false
  end

  def matches
    @user = LikesUser.find_by(user_id: params[:id])
    if @user.extra["user_type"] == 'graduate'
      @matches = LikesLike.where(likeable_type: 'User', likeable_id: @user.user_id, match: true)
    elsif @user.extra["user_type"] == 'employer' or @user.extra["user_type"] == 'individual_employer'
      @job_ids = LikesJob.where(user_id: @user.user_id).map(&:job_id)
      @matches = LikesLike.where(likeable_type: 'Job', likeable_id: @job_ids, match: true)
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

end