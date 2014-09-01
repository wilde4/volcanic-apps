class InventoryController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_action :set_inventory_item, only: [:get_inventory]

  # GET /inventories/index
  # Outputs all Inventory Items in the system
  def index
    @items = Inventory.all || []

    respond_to do |format|
      format.html
      format.json { render json: {success: true, items: @items } }
    end
  end

  # Loads up the HTML form for use in the apps dashboard
  def new
    @inventory = Inventory.new
  end

  def edit
    @inventory = Inventory.find(params[:data][:inv_id])
    @inv_id = params[:data][:inv_id]
  end

   def update
    @inventory = Inventory.find(params[:inventory][:id])
    respond_to do |format|
      if @inventory.update(inventory_params)
        format.html { redirect_to action: 'index' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST
  # Creates a new Inventory Item
  # Params:
  #   * name - Name of the new Inventory Item (Promotional Name?)
  #   * start_date - Date that the Inventory Item will be active
  #   * end_date - Date that ends the Inventory Item active period
  #   * price - Price to charge for this Inventory Item
  def create_item
    @inventory = Inventory.new(
      name: params[:inventory][:name],
      start_date: params[:inventory][:start_date],
      end_date: params[:inventory][:end_date],
      price: params[:inventory][:price],
      object_type: params[:inventory][:object_type])

    respond_to do |format|
      if @inventory.save
        @items = Inventory.all || []
        format.html { render action: 'index' }
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
    @inventory = Inventory.where(object_type: params[:type]).within_date
    respond_to do |format|
      format.json { render json: { success: true, items: @inventory } }
    end
  end

  # GET /inventory/best_price
  # Get the best price for an Inventory item
  # Params:
  #   * type - Type of object to lookup (Job, Match, etc)
  def cheapest_price
    @inventory = Inventory.where(object_type: params[:type]).within_date.sort_by{|i| i.price }
    respond_to do |format|
      format.json { render json: { success: true, item: @inventory.first } }
    end
  end

private

  def inventory_params
    params.require(:inventory).permit(:name, :start_date, :end_date, :price, :object_type)
  end

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end