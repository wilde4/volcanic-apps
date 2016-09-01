class PagesCreatedPerMonthController < ApplicationController
  respond_to :json

  def get_pages_created

    puts "\n\n"
    puts params.inspect
    puts "\n\n"


    pages_record = PagesCreatedPerMonth.find_by(site_id: params[:site_id], date: params[:date])


    json = { 
      site_id:       params[:site_id],
      date:          params[:date],
      created_pages: 0,
      total_pages:   0
    }


    if !pages_record.nil?
      json[:created_pages] = pages_record.created_pages  
      json[:total_pages] = pages_record.total_pages  
    end


    respond_to do |format|
      format.json { render json: json }
    end
  end


  def calculate_pages_created

    url = [ params[:site_url], "/", "sitemap.xml"]

    status =        200
    created_pages = 0
    total_pages =   0

    begin
      response = HTTParty.get( url.join("") )
      list_of_urls = response["urlset"]["url"]

      if !list_of_urls.blank?

        previous_page_record = PagesCreatedPerMonth.find_by(site_id: params[:site_id], date: (Date.strptime(params[:date], "%Y-%m-01") - 1.month).beginning_of_month)

        if !previous_page_record.nil?
          value = list_of_urls.size - previous_page_record.total_pages
          created_pages = value if value > 0
        else
          created_pages = list_of_urls.size
        end

        total_pages = list_of_urls.size
      end

    rescue Exception => e

      status = 500
    ensure
      _write_to_database(
        params[:site_id],
        params[:date],
        created_pages,
        total_pages
      )
      render :nothing => true, :status => status, :content_type => 'text/html'
    end
  end


  def _write_to_database(site_id, date, created_pages, total_pages)
    pages_record = PagesCreatedPerMonth.find_by(site_id: site_id, date: date)

    if pages_record.nil?
      PagesCreatedPerMonth.create({
        site_id: site_id,
        date: date,
        created_pages: created_pages,
        total_pages: total_pages
      })      
    end
  end

end
