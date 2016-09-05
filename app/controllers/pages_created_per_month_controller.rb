class PagesCreatedPerMonthController < ApplicationController
  respond_to :json

  # after_filter :setup_access_control_origin
  protect_from_forgery with: :null_session
  before_action :set_key, only: [:get_pages_created, :calculate_pages_created]
  # skip_before_filter :verify_authenticity_token


  def get_pages_created

    date = Date.strptime(params[:date], "%Y-%m-01")

    sql = "
      SELECT
        (
        SELECT COUNT(*)
        FROM `pages_created_per_months`
        WHERE `pages_created_per_months`.`date_deleted` IS NULL
        ) as 'Total_Pages',
        
        (
        SELECT COUNT(*)
        FROM `pages_created_per_months`
        WHERE `pages_created_per_months`.`date_deleted` IS NOT NULL 
        AND `pages_created_per_months`.`date_added` BETWEEN '#{date.beginning_of_month}' AND '#{date.end_of_month}'
        ) as 'Deleted_Pages',
        
        (
        SELECT COUNT(*)
        FROM `pages_created_per_months`
        WHERE `pages_created_per_months`.`date_deleted` IS NULL   
        AND `pages_created_per_months`.`date_added` BETWEEN '#{date.beginning_of_month}' AND '#{date.end_of_month}'
        ) as 'Created_Pages'

      
      FROM `pages_created_per_months`
      WHERE `pages_created_per_months`.`dataset_id` = #{params[:the_dataset_id]}
      GROUP BY date_format(`pages_created_per_months`.`date_added`, '%Y-%m-01')
      LIMIT 1;
    "

    
    records_array = ActiveRecord::Base.connection.execute(sql)

    if records_array.size > 0

      json = { 
        date:          params[:date],
        total_pages:   records_array.first[0],
        deleted_pages: records_array.first[1],
        created_pages: records_array.first[2]
      }

    else

      json = { 
        date:          params[:date],
        total_pages:   0,
        deleted_pages: 0,
        created_pages: 0
      }

    end




    respond_to do |format|
      format.json { render json: json }
    end
  end


  def calculate_pages_created

    url = AppSetting.find_by(dataset_id: params[:dataset_id])
    url = (!url.nil? ? url.settings["sitemap"] : nil)

    return if url.nil?

    status =        200
    created_pages = 0
    total_pages =   0

    begin
      response = HTTParty.get( url )
      list_of_urls = response["urlset"]["url"]

      if !list_of_urls.blank?

        existing_urls = []
        existing_urls_deleted = []

        PagesCreatedPerMonth.all.each do |page|
          page.date_deleted.blank? ? (existing_urls << page.url) : (existing_urls_deleted << page.url)
        end

        new_urls = list_of_urls.map!{|m| m["loc"]}


        # Get all values in: NEW URL COLLECTION that don't appear in EXISTING URL COLLECTION --- these are CREATED
        collection = (new_urls - existing_urls)
        collection.each do |x|
          PagesCreatedPerMonth.create({
            url: x,
            date_added: Date.today,
            dataset_id: params[:dataset_id]
          }) 
        end


        # Get all values in: EXISTING URL COLLECTION that don't appear in NEW URL COLLCETION --- these are DELETED
        collection = (existing_urls - new_urls)
        collection.each do |x|
          PagesCreatedPerMonth.where(url: x).update_all({
            date_deleted: Date.today
          }) 
        end


        # Get all values in: EXISTING URL COLLECTION that are deleted AND appear in NEW URL COLLECTION --- these are NEW CREATED
        collection = (existing_urls_deleted & new_urls)
        collection.each do |x|
          PagesCreatedPerMonth.where("url = ? AND date_deleted IS NOT NULL", x, nil).update_all({
            date_deleted: Date.today
          }) 
        end
      end

    rescue Exception => e
      status = 500
    ensure
      render :nothing => true, :status => status, :content_type => 'text/html' if !params[:no_render].present?
    end
  end


  def update_settings

    response_code = 500

    render json: { success: false, error: "<b>Error Occurred:</b> URL is blank" } and return if params["settings"]["sitemap"].blank?

    begin
      response = HTTParty.get(params["settings"]["sitemap"])
      response_code = response.code if !response.nil?

      if response_code == 200
        params[:no_render] = true

        settings = AppSetting.find_by(dataset_id: params[:dataset_id])

        if settings.present?
          settings.update(settings: params[:settings])
        else
          settings = AppSetting.create(dataset_id: params[:dataset_id], settings: params[:settings])
        end
        calculate_pages_created
        render json: { success: true, message: 'Updated App Settings.' }
      else
        render json: { success: false, error: "<b>Error Occurred:</b> URL is invalid" }
      end

    rescue Exception => e
      response_code = 500
      render json: { success: false, error: "<b>Error Occurred:</b> URL is invalid" }
    end
  end

end
