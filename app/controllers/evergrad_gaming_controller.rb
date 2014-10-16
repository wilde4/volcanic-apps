class EvergradGamingController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_action :set_achievement, only: [:achievement, :tiered_achievement]

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  # POST /evergrad_gaming/action_complete.json
  # Sets an achievement to true
  # Params:
  #   * user_id : The user to lookup for the achievement
  #   * achievement : Name of the achievement to update
  def action_complete
    status = ""
    completed_achievements = []

    if params[:user]
      @achievement = Achievement.find_or_create_by(user_id: params[:user][:id]) do |a|
        a.signed_up = true
      end

      if params[:user][:percentage_complete].present? && params[:user][:percentage_complete] > 99
        completed_achievements << :completed_profile
      end

      if params[:registration_answers_hash].present? && params[:registration_answer_hash]['video-introduction'].present?
        completed_achievements << :uploaded_cv
      end

      if params[:evergrad_gaming][:achievement].present?
        completed_achievements << params[:evergrad_gaming][:achievement]
      end
      
      completed_achievements.each do |a_name|
        status.concat update_achievement(@achievement, a_name).to_json
      end
    else
      status = "You must provide a user to set achievements."
    end

    render json: status
  end

  # GET /evergrad_gaming/available_achievements
  # Returns the names of the available achievements as JSON
  def available_achievements
    render json: achievements
  end

    # GET /evergrad_gaming/achievement
  # Finds a users achievement record, returns as JSON
  # Params:
  #   * user_id : The user to lookup for the achievement
  def achievement
    render json: @achievement
  end

  # GET /evergrad_gaming/tiered_achievement
  # Finds a users achievement, splits the actions into br/sl/gld tiers
  # Params:
  #   * user_id : The user to lookup for the achievement
  def tiered_achievement
    render json: {
      id: @achievement.id,
      user_id: @achievement.user_id,
      level: @achievement.level,
      bronze: { signed_up: @achievement.signed_up, downloaded_app: @achievement.downloaded_app },
      silver: { uploaded_cv: @achievement.uploaded_cv, liked_job: @achievement.liked_job },
      gold:   { shared_social: @achievement.shared_social, completed_profile: @@achievement.completed_profile } 
    }
  end

private

  def set_achievement
    return false if params[:evergrad_gaming].blank?
    @achievement = Achievement.find_or_create_by(user_id: params[:evergrad_gaming][:user_id]) do |a|
      a.signed_up = true
    end
  end

  # Updates an achievement record, and calcaulates any change in level:
  def update_achievement(achievement, achievement_name)
    status = ""

    if achievement.nil?
      status = { status: "Failed to find Achievement record for User #{uid}.\n" }
    else
      if !achievements.include?(achievement_name.to_sym)
        status = { status: "'#{achievement_name}' is not a valid achievement.\n" }
      else
        save_state = achievement.update_attributes(achievement_name.to_sym => true)
        level_increased = calculate_level(achievement)
        status = save_state ? "Record Updated" : "Failed to update record"
        status = { status: status, level_increased: level_increased}
      end
    end
    status
  end

  # Calculate whether a level has been attained
  # Returns: Boolean, whether the user increased in level
  def calculate_level(achievement)
    level = "bronze" if achievement.signed_up && achievement.downloaded_app
    level = "silver" if level == "bronze" && achievement.uploaded_cv && achievement.liked_job
    level = "gold"   if level == "silver" && achievement.shared_social && achievement.completed_profile

    if !level.nil? && achievement.level != level
      achievement.update_attributes(level: level)
      return true
    end
    return false
  end

  # Available Achievement Actions
  def achievements
    [
      :signed_up, :downloaded_app, :uploaded_cv,
      :liked_job, :shared_social, :completed_profile
    ]
  end
end