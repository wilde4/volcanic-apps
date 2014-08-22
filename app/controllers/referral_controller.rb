require 'securerandom'
class ReferralController < ApplicationController

  before_action :set_referral, only: [:referral_token_confirmed]

  # POST /referrals/create_referral
  # Creates a referral for a User ID
  # Params:
  #   * user - User ID to associate with
  #   * referred_by - User ID that referred the new person
  #   * token_length - Length of the token to generate
  def create_referral
    referral = Referral.new
    referral.user_id = params[:user]
    referral.referred_by = params[:referred_by]
    referral.generate_token(params[:token_length].to_i)

    respond_to do |format|
      if referral.save
        format.json { render json: {
            status: "OK", referral_token: referral.token
          } }
      else
        format.json { render json: {
            status: "Error: #{referral.errors.full_messages.join(', ')}"
          } }
      end
    end
  end

  # GET /referrals/referral
  # Grabs the record for the referral token
  # Params:
  #   * token - Referral token to lookup
  def get_referral
    referral = Referral.find_by(token: params[:token])

    respond_to do |format|
      format.json { render json: { 
          status: "OK", referral: referral
        } }
    end
  end

  # GET /referrals/referred_by
  # Get all users that another user has referred
  # Params:
  #   * user - User ID to find as referred_by
  def get_referred_by
    referrals = Referral.where(referred_by: params[:user])
    



  # GET /referrals(/:id)/confirmed
  # Params:
  #   * id - Target user to load
  def referral_confirmed
    referral = Referral.find_by(user_id: params[:id])

    status = !referral.nil? ? "OK" : "Error: Record not found"
    confirmed = !referral.nil? && referral.confirmed ? true : false

    respond_to do |format|
      format.json { render json: { status: status, confirmed: confirmed } }
    end
  end

  # GET /referrals(/:id)/generate_referral_token
  # Params:
  #   * length - Number of bytes to generate
  def generate
    length = params[:length] ? params[:length].to_i : 16
    referral_token = SecureRandom.hex(length).upcase

    respond_to do |format|
      format.json { render json: { 
          status: "OK",
          referral_token: referral_token
        }
      }
    end
  end

  
  # GET /referrals/referrals_for_period
  # Params:
  #   * start_date - Start of reporting period
  #   * end_date   - End of reporting period
  def referrals_for_period
    referrals = Referral.where(created_at: params[:start_date]...params[:end_date])

    respond_to do |format|
      format.json { render json: {
          status: "OK",
          length: referrals.count,
          referrals: referrals
        }
      }
    end
  end

  # GET /referrals/most_referrals
  # Params:
  #   * limit - Number of users to take
  def most_referrals

    respond_to do |format|
      format.json { render json: {
          status: "OK",
          confirmed: true || false
        }
      }
    end
  end


  # POST /referrals(/:id)/confirm_referral_token
  # Params:
  #   * referral_token - Token to confirm
  def confirm_referral_token
  end

  # POST /referrals(/:id)/revoke_referral
  def revoke_referral
  end

private


end