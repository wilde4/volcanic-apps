class ReferralController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_filter :verify_authenticity_token

  require 'csv'
  respond_to :json, :csv

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  before_action :set_referral, except: [
    :index, :create_referral, :funds_earned, :funds_owed, :confirm, :notification_events,
    :referrals_for_period, :most_referrals, :referral_by_user, :payment_form,
    :save_payment_info, :referral_report, :activate_app, :deactivate_app]

  before_action :set_key, only: [:create_referral, :full_referral,
    :referrals_for_period]

  def index
    render layout: false
  end

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
      referral.revoked = referral.confirmed = false
      referral.dataset_id = @key.app_dataset_id

      # find the referring user if we have to:
      if params['registration_answer_hash']['referral-code']
        referer = Referral.find_by(token: params['registration_answer_hash']['referral-code'])     
        referral.referred_by = referer.id if referer

        fee_item = Inventory.by_object('Referral')
                            .select{|iv| iv.within_date}
                            .sort_by{|i| i.price }
                            .first

        if fee_item
          referral.fee = fee_item.price
        end
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
  # A call to get referral data - excludes payment info
  def get_referral
    @referral.account_name = @referral.account_number = @referral.sort_code = nil

    respond_to do |format|
      format.json { render json: { success: true, referral: @referral }}
    end
  end

  # GET /referrals(/:id)/full_referral
  # A call to get all referral data
  def full_referral
    respond_to do |format|
      format.json { render json: { success: true, referral: @referral }}
    end
  end

  # GET /referrals/referral
  # Params:
  #   * user_id - UID to lookup
  def referral_by_user
    @referral = Referral.find_by(user_id: params[:user_id])
    respond_to do |format|
      format.json { render json: { success: true, referral: @referral }, methods: [:funds_earned, :funds_owed] }
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

  # POST /referrals/confirm
  # Confirms a user's referral token
  def confirm
    logger.info "--- params = #{params.inspect}"
    @referral = Referral.find_by(user_id: params[:like][:user_id])
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
    if params[:data]
      if params[:data]['start_date(1i)'].present?
        start_date = Date.new params[:data]["start_date(1i)"].to_i, params[:data]["start_date(2i)"].to_i, params[:data]["start_date(3i)"].to_i
        end_date = Date.new params[:data]["end_date(1i)"].to_i, params[:data]["end_date(2i)"].to_i, params[:data]["end_date(3i)"].to_i
      elsif params[:data][:start_date].present?
        start_date = Date.parse(params[:data][:start_date])
        end_date = Date.parse(params[:data][:end_date])
      else
        start_date = Date.parse("2010-01-01")
        end_date = Date.parse("2020-01-01")
      end
    else
      start_date = Date.parse("2010-01-01")
      end_date = Date.parse("2020-01-01")
    end


    refgroups = []

    referrals = Referral.by_dataset(@key.app_dataset_id)
                        .where(created_at: start_date...end_date)

    refcounts = referrals.group(:referred_by).count
    refcounts.delete(nil)

    # sort each referrer group into it's own collection:
    refcounts.each do |k,v|
      referer = referrals.find_by(id: k)
      if referer
        # curl -X POST -H "Content-Type: application/json" -d '{"api_key" : "42a8871d56d39ab3181a39cf95507ba6", "event_name" : "graduate_owed_fees", "user_id" : "2433", "outstanding_amount" : '45.50', "amount_earned_already" : '30.00'}' http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json
        # @response = HTTParty.post('http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json', {:body => {event_name: 'graduate_owed_fees', api_key: @key.api_key, user_id: referer.user_id, outstanding_amount: '45.50', amount_earned_already: '30.00'}, :headers => { 'Content-Type' => 'application/json' }})
        ref = ["#{referer.full_name} (#{v} Referrals)", referrals.select{ |r| r.referred_by == k } ]
        refgroups << ref
      end
    end
    
    respond_to do |format|
      format.html {
        @referrals = refgroups
        render action: 'overview', layout: false
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
    metrics = Referral.by_dataset(params[:dataset_id])
                      .group(:referred_by)
                      .count.sort_by{|k,v| v}
                      .reverse.reject{|r| r[0] == nil}

    if params[:data].present? and params[:data][:limit].present?
      limit = params[:data][:limit].to_i
    else
      limit = metrics.count > 100 ? metrics.count / 10 : metrics.count
    end 

    @referrals = metrics[0...limit]

    @referrals.each do |ref|
      referrer = Referral.find(ref[0])
      ref.unshift(referrer.partial_name)
    end

    respond_to do |format|
      format.html { render action: 'most_referrals' }
      format.json { render json: { success: true, status: "OK", referrals: @referrals } }
    end
  end

  def payment_form
    @referral = Referral.find_by(user_id: params[:data][:user_id]) if params[:data]
    render nothing: true if @referral.blank?
  end

  def save_payment_info
    @referral = Referral.find(params[:referral][:id])

    respond_to do |format|
      if @referral.update(referral_params)
        format.json { render json: {success: true, status: "OK" }}
      else
        format.json { render json: {
          success: false, status: "Error: #{@referral.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def referral_report
    render nothing: true, layout: false unless @key
    @refs = Referral.where(fee_paid: false, confirmed: true, revoked: false || nil)
    respond_to do |format|
      format.csv { send_data @refs.to_csv }
    end
  end

  def notification_events
    render json: {
      graduate_owed_fees: {
        description: 'A graduate is owed fees',
        targets: [:user],
        tags: [:name, :outstanding_amount, :amount_earned_already]
      },
      graduate_not_owed_fees: {
        description: 'A graduate is not owed fees',
        targets: [:user],
        tags: [:name, :outstanding_amount, :amount_earned_already]
      }
    }
  end


private

  def set_referral
    @referral = Referral.find(params[:id])
  end

  def referral_params
    params.require(:referral).permit(:id, :account_name)
  end
end