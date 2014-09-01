class InventoryController < ApplicationController
  protect_from_forgery with: :null_session#, if: Proc.new { |c| c.request.format == 'application/json' }
  respond_to :json

  before_action :set_inventory_item, only: [:get_inventory]

  def index
    @items = Inventory.all || []

    respond_to do |format|
      format.html
      format.json { render json: {success: true, items: @items } }
    end
  end

  def new
    @inventory = Inventory.new
  end

  # POST
  # Creates a new Inventory Item
  # Params:
  #   * name - 
  #   * start_date - 
  #   * end_date -
  #   * price - 
  def create_item
    @inventory = Inventory.new(
      name: params[:inventory][:name],
      start_date: params[:inventory][:start_date],
      end_date: params[:inventory][:end_date],
      price: params[:inventory][:price],
      object_type: params[:inventory][:object_type])

    respond_to do |format|
      if @inventory.save
        format.html { redirect_to 'http://evergrad.localhost.volcanic.co:3000/admin/apps/9/index' }
        format.json { render json: { success: true, item: @inventory }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{@inventory.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  # GET /inventory(/:id)/inventory
  # Get an inventory by an Inventory ID
  def get_inventory
    respond_to do |format|
      format.json { render json: { success: true, item: @inventory } }
    end
  end

  # GET /inventory/available
  # Get all available inventory for an Object Type:
  # Params:
  #   * type - Type of object to lookup (Job, Match, etc)
  def get_available
    @inventory = Inventory.where(object_type: params[:type])
    respond_to do |format|
      format.json { render json: { success: true, items: @inventory } }
    end
  end

private

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end