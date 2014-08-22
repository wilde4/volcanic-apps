require 'securerandom'

class ReferralController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # POST /referrals/create_referral
  # Creates a referral for a User ID
  # Params:
  #   * user - User ID to associate with
  #   * token_length - Length of the token to generate
  # curl -X POST -H "Content-Type: application/json" -d '{"user" : {"id" : "2435"}}' http://0.0.0.0:3001/referrals/create_referral.json
  def create_referral
    referral = Referral.new
    referral.user_id = params[:user][:id]
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

  # GET /referrals/generate_referral_token
  # Params:
  #   * length - Number of bytes to generate
  def generate_referral_token
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

  # GET /referrals/referral_token_exists
  # Params:
  #   * referral_token - Token to check
  def referral_token_exists

    respond_to do |format|
      format.json { render json: {
          status: "OK",
          exists: true || false
        }
      }
    end
  end

  # GET /referrals/referral_token_confirmed
  # Params:
  #   * referral_token - Token to check
  def referral_token_confirmed

    respond_to do |format|
      format.json { render json: {
          status: "OK",
          confirmed: true || false
        }
      }
    end
  end

  # GET /referrals/referrals_for_period
  # Params:
  #   * start_date - Start of reporting period
  #   * end_date   - End of reporting period
  def referrals_for_period

    respond_to do |format|
      format.json { render json: {
          status: "OK",
          referrals: nil
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

end