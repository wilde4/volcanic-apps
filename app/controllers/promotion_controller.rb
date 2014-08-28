class PromotionController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_action :set_promotion, except: [:overview, :create_promotion]

  # POST /referrals/create_referral
  # Creates a new Promotion
  # Params:
  #   * name - 
  #   * start_date - 
  #   * end_date -
  #   * price - 
  def create_promotion
    promotion = Promotion.new(
      name: params[:name],
      start_date: params[:start_date],
      end_date: params[:end_date],
      price: params[:price])

    respond_to do |format|
      if promotion.save
        format.json { render json: { success: true, promotion: promotion }}
      else
        format.json { render json: {
          success: false, status: "Error: #{promotion.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def overview
    @defaults = Promotion.where(default: true) || []
    @promotions = Promotion.where(default: false) || []
  end

  # GET /promotions(/:id)/promotion
  def get_promotion
    respond_to do |format|
      format.json { render json: { success: true, promotion: @promotion } }
    end
  end

  # GET /promotions(/:id)/default
  def default
    respond_to do |format|
      format.json { render json: { success: true, default: @promotion.default } }
    end
  end


  # GET /promotions(/:id)/active
  def active
    respond_to do |format|
      format.json { render json: { success: true, active: @promotion.active } }
    end
  end

  # GET /promotions(/:id)/toggle_active
  def toggle_active
    @promotion.active = !@promotion.active

    respond_to do |format|
      if @promotion.save
        format.json { render json: { success: true, active: @promotion.active } }
      else
        format.json { render json: {
          success: false, status: "Error: #{@promotion.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  def toggle_default
    @promotion.default = !@promotion.default

    respond_to do |format|
      if @promotion.save
        format.json { render json: { success: true, default: @promotion.default } }
      else
        format.json { render json: {
          success: false, status: "Error: #{@promotion.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

private

  def set_promotion
    @promotion = Promotion.find(params[:id])
  end
end