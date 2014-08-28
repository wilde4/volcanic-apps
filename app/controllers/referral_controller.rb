class ReferralController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_action :set_referral, except: [
    :create_referral, :funds_earned, :funds_owed,
    :referrals_for_period, :most_referrals]

  # POST /referrals/create_referral
  # Creates a referral for a User ID
  # Params:
  #   * user - User ID to associate with
  #   * referred_by - User ID that referred the new person
  #   * token_length - Length of the token to generate
  # curl -X POST -H "Content-Type: application/json" -d '{"user" : {"id" : "2435"}}' http://0.0.0.0:3001/referrals/create_referral.json
  def create_referral
    ref = Referral.find_by(user_id: params[:user][:id])
    unless ref.present?
      referral = Referral.new
      referral.user_id = params[:user][:id]
      referral.first_name = params[:user_profile][:first_name]
      referral.last_name = params[:user_profile][:last_name]

      # find the referring user if we have to:
      if params[:token]
        referer = Referrer.find_by(token: params[:referrer_token])
        referral.referred_by = referrer.user_id if referrer
      end

      respond_to do |format|
        if referral.save
          format.json { render json: { success: true, referral_token: referral.token } }
        else
          format.json { render json: { success: false, status: "Error: #{referral.errors.full_messages.join(', ')}" } }
        end
      end
    end
  end

  # GET /referrals(/:id)/referral
  def get_referral
    respond_to do |format|
      format.json { render json: { success: true, referral: @referral } }
    end
  end

  # GET /referrals/funds_earned
  # Returns a historical count of all money earned
  # Params:
  #   * user - User ID used in lookup
  def funds_earned
    earned = Referral.where(referred_by: params[:user_id], fee_paid: true)
                     .map(&:fee).reduce(:+)

    respond_to do |format|
      format.json { render json: { success: true, value: earned } }
    end
  end

  # GET /referrals/funds_owed
  # Returns the outstanding money owed to user
  # Params:
  #   * user_id - User ID used in lookup
  def funds_owed
    owed = Referral.where(referred_by: params[:user_id],
                          confirmed: true, revoked: false, fee_paid: false)
                   .map(&:fee).reduce(:+)

    respond_to do |format|
      format.json { render json: { success: true, value: owed } }
    end
  end


  # GET /referrals(/:id)/referred
  # Get who the User referred
  # Params:
  #   * user - User ID to find as referred_by
  def get_referred
    referrals = Referral.where(referred_by: params[:id])

    respond_to do |format|
      format.json { render json: { 
        success: true, count: referrals.count, referrals: referrals
      } }
    end
  end

  # GET /referrals(/:id)/confirmed
  # Params:
  #   * id - Target user to load
  # Returns true/false, or null on error
  def confirmed
    if @referral.nil?
      status = "Error: Record not found"
      confirmed = nil
    else 
      status = "OK"
      confirmed = @referral.confirmed
    end

    respond_to do |format|
      format.json { render json: {
        success: status == "OK", status: status, confirmed: confirmed 
      } }
    end
  end

  # GET /referrals(/:id)/paid
  # Params:
  #   * id - Target user to load
  # Returns true/false, or null on error
  def paid
    if @referral.nil?
      status = "Error: Record not found"
      paid = nil
    else 
      status = "OK"
      paid = @referral.fee_paid
    end

    respond_to do |format|
      format.json { render json: {
        success: status == "OK", status: status, paid: paid
      } }
    end
  end


  # GET /referrals(/:id)/generate
  # Params:
  #   * length - Number of bytes to generate
  def generate
    if @referral
      referral.generate_token
      success = true
    else
      success = false
      status = "Error: Record not found"
    end

    respond_to do |format|
      format.json { render json: {
        success: success, status: status, referral: @referral
      } }
    end
  end

  # POST /referrals(/:id)/confirm
  # Confirms a user's referral token
  def confirm
    if @referral
      @referral.confirmed = true
      @referral.confirmed_at = DateTime.now
      @referral.save
      status = "OK"
    else
      status = "Error: Record not found"
    end

    respond_to do |format|
      format.json { render json: {
        success: status == "OK", status: status
      } }
    end
  end

  # GET /referrals(/:id)/revoke
  # Revokes a user's referral token
  def revoke
    if @referral
      @referral.revoked = true
      @referral.revoked_at = DateTime.now
      @referral.save
      status = "OK"
    else
      status = "Error: Record not found"
    end

    respond_to do |format|
      format.json { render json: {
        success: status == "OK", status: status
      } }
    end
  end
  
  # GET /referrals/referrals_for_period
  # Gets the referrals that occurred within a time period
  # Params:
  #   * start_date - Start of reporting period
  #   * end_date   - End of reporting period
  def referrals_for_period
    start_date = params[:start_date] || Date.parse("2000-01-01")
    end_date = params[:end_date] || Date.parse("2050-01-01")

    refgroups = []

    referrals = Referral.where(created_at: start_date...end_date)
    referral_groupings = referrals.group(:referred_by).count.sort_by{|k,v| v}.reverse

    # sort each referrer group into it's own collection:
    referral_groupings.each do |k,v|
      refgroups << referrals.select{ |r| r.referred_by == k }
    end

    respond_to do |format|
      format.html {
        @referrals = refgroups
        render action: 'overview'
      }
      format.json { render json: {
          success: true, length: referrals.count, referrals: refgroups
        }
      }
    end
  end

  # GET /referrals/most_referrals
  # Returns a list of users who referred the most people
  # Params:
  #   * limit - Number of users to take
  def most_referrals
    metrics = Referral.group(:referred_by).count.sort_by{|k,v| v}.reverse
    metrics.delete(nil)

    limit = params[:limit] ? params[:limit].to_i : metrics.count / 10

    @referrals = metrics[0...limit]

    @referrals.each do |referral|
      refdata = Referral.find_by(user_id: referral[0])
      referral.unshift(refdata.first_name, refdata.last_name)
    end

    respond_to do |format|
      format.html { render action: 'most_referrals' }
      format.json { render json: { success: true, status: "OK", referrals: @referrals } }
    end
  end

private
  def set_referral
    @referral = Referral.find(params[:id])
  end
end