class InventoryController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

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
    @inv_objs = Inventory.inventory_objects
    @app_server = app_server_host
  end

  def edit
    @inventory = Inventory.find(params[:data][:inv_id])
    @inv_objs = Inventory.inventory_objects
    @app_server = app_server_host
  end

   def update
    @inventory = Inventory.find(params[:inventory][:id])
    respond_to do |format|
      if @inventory.update(inventory_params)
        format.html { redirect_to action: 'index' }
        format.json { render json: { success: true, item: @inventory }}
      else
        format.html { render action: 'edit' }
        format.json { render json: {
          success: false, status: "Error: #{@inventory.errors.full_messages.join(', ')}"
        }}
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
    @inventory = Inventory.new(inventory_params)

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
    inv_obj = Inventory.object_by_name(params[:type])
    if inv_obj
      @inventory = Inventory.by_object(inv_obj[:id]).select{|iv| iv.within_date}
    end

    respond_to do |format|
      format.json { render json: { success: true, items: @inventory || [] } }
    end
  end

  # GET /inventory/best_price
  # Get the best price for an Inventory item
  # Params:
  #   * type - Type of object to lookup (Job, Match, etc)
  def cheapest_price
    inv_obj = Inventory.object_by_name(params[:type])
    if inv_obj
      @inventory = Inventory.by_object(inv_obj[:id]).select{|iv| iv.within_date}.sort_by{|i| i.price }
    end

    respond_to do |format|
      format.json { render json: { success: true, item: @inventory.first } }
    end
  end

=begin
  # POST /inventory/post_purchase
  # An action that can be called on a purchased object
  # Params:
  #   * domain       - Where we're sending the request, usually 
  #   * inventory_id - The record for the item purchased
  #   * purchased_id - The specific record ID that was purchased (Job(10), User(1442) etc.)
  #   * api_key      - Api Key for Oliver API access
  def post_purchase

    if params[:data][:inventory_id] && params[:data][:api_key]
      item = Inventory.find(params[:data][:inventory_id])
      resource = item.object_type.downcase.pluralize(2)
      endpoint_str = "#{params[:data][:domain]}/api/v1/#{resource}/#{params[:data][:purchased_id]}.json"

      # Work out the field to be edited, will be a record in future
      case item.object_type
      when "User"
        attribute = { email: 'SharksWithLaserBeams@gmail.com' }
      end

      request_data = {
        api_key: params[:data][:api_key],
        item.object_type.to_sym => attribute
      }

      response = HTTParty.put(endpoint_str, request_data)

      respond_to do |format|
        format.json{ render json: response.body }
      end

    end
  end
=end

private
  def inventory_params
    params.require(:inventory).permit(:id, :name, :start_date, :end_date, :price, :inventory_object_id)
  end

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end