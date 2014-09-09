class EvergradGamingController < ApplicationController

  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  # POST /evergrad_gaming/action_complete.json
  # Sets an achievement to true
  # Params:
  #   * user_id : The user to lookup for the achievement
  #   * achievement_name : Name of the achievement to update
  def action_complete
    achivement_name = params[:achievement_name]
    status = update_achievement(params[:user_id], params[:achievement_name])

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
    achievement = Achievement.find_by(user_id: params[:user_id])
    render json: achievement 
  end

  # GET /evergrad_gaming/tiered_achievement
  # Finds a users achievement, splits the actions into br/sl/gld tiers
  # Params:
  #   * user_id : The user to lookup for the achievement
  def tiered_achievement
    achievement = Achievement.find_by(user_id: params[:user_id])
    render json: {
      id: achievement.id,
      user_id: achievement.user_id,
      level: achievement.level,
      bronze: { signed_up: achievement.signed_up, downloaded_app: achievement.downloaded_app },
      silver: { uploaded_cv: achievement.uploaded_cv, liked_job: achievement.liked_job },
      gold:   { shared_social: achievement.shared_social, completed_profile: achievement.completed_profile } 
    }
  end

private

  # Updates an achievement record, and calcaulates any change in level:
  def update_achievement(uid, achievement_name)
    status = ""
    achievement = Achievement.find_by(user_id: uid)

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

    if achievement.level != level
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