# EclipseApp.poll_jobs_feed
class EclipseApp
  def poll_jobs_feed
    puts '- BEGIN poll_jobs_feed'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'eclipse')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host
      settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
      unless settings.present? && settings.settings.present? && settings.settings["Feed URL"].present?
        puts "No Feed URL configured - skipping"
        next
      end
      parse_jobs
    end

    puts '- END poll_jobs_feed'
  end

  def parse_jobs
    @job_data = get_xml
    jobs = @job_data.xpath("//item")
    
    jobs.each do |job|
      @job_payload = Hash.new
      @job_payload["job[api_key]"] = @key.api_key

      EclipseApp.austin_andrews_payload(job) if @key.app_dataset_id == 83

      puts "--- @job_payload = #{@job_payload.inspect}"
      post_payload(@job_payload) unless @job_payload["job[discipline]"].blank?
    end
  end

private

  def austin_andrews_payload(job)
    # GET WHAT WE CAN FROM XML
    # puts "--- job.xpath('author') = #{job.xpath("author").inspect}"
    disciplines = []
    @job_payload['job[job_title]'] = job.xpath('title').text.strip
    # @job_payload['job[discipline]'] = job.xpath('category').text.strip
    disciplines << job.xpath('category').text.strip
    @job_payload['job[created_at]'] = job.xpath('pubDate').text.strip

    # SCRAPE WEB PAGE
    page_url = job.xpath("link").text.strip.gsub('www.austinandrew.co.uk', 'austinandrew.recruitment-websites.co.uk')
    puts "--- page_url = #{page_url}"
    begin
      page = Nokogiri::HTML(open(page_url))
      ref = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_RefNo').text.strip
      @job_payload['job[job_reference]'] = ref
      # IDENTIFY SUPER DISCIPLINE
      ref_acronym = ref.split('-').first
      case ref_acronym
      when 'SCD'
        disciplines << 'Strategy & Corporate Development'
      when 'PAC'
        disciplines << 'People & Change'
      when 'CGV'
        disciplines << 'Corporate Governance'
      when 'IPE'
        disciplines << 'Investment Banking & Private Equity'
      end
      @job_payload['job[job_location]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Location').text.strip
      @job_payload['job[job_type]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_LengthofContract').text.strip
      @job_payload['job[salary_free]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Salary').text.strip
      salary_val = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Salary').text.strip.tr('£,', '')
      @job_payload['job[salary_low]'] = @job_payload['job[salary_high]'] = salary_val
      extracted_desc = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_JobDescription').children.to_s
      @job_payload['job[job_description]'] = '<p>' + extracted_desc + '</p>'
      # EXTRACT CONSULTANT EMAIL ADDRESS
      c_email = extracted_desc.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+/)
      puts "--- c_email = #{c_email}"
      @job_payload['job[application_email]'] = c_email if c_email.present?
      @job_payload['job[contact_email]'] = c_email if c_email.present?
    rescue Exception => e
      puts "--- Failed to open page_url = #{e.inspect}"
      @job_payload = {}
    end

    @job_payload['job[discipline]'] = disciplines.join(', ')

    # Expiry = date + 60 days
    begin
      date = Date.parse(@job_payload["job[created_at]"])
      @job_payload["job[expiry_date]"] = date + 365.days
    rescue Exception => e
      puts "[WARN] #{e}"
      @job_payload["job[expiry_date]"] = Date.today + 365.days
    end
  end

  def get_xml
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    doc = Nokogiri::XML(open(settings.settings["Feed URL"]))
  end

  def post_payload(payload)
    # net = Net::HTTP.new(@key.host, 80)
    # # net = Net::HTTP.new(@key.host, 3000)
    # request = Net::HTTP::Post.new("/api/v1/jobs.json")
    # request.set_form_data( payload )
    # net.read_timeout = net.open_timeout = 10

    begin
      response = HTTParty.post("http://#{@key.host}/api/v1/jobs.json", { body: payload })
      # response = net.start do |http|
      #   http.request(request)
      # end

      puts "#{response.code} - #{response.read_body}"
      return response.code.to_i == 200
    rescue Exception => e
      puts "[FAIL] http.request failed to post payload: #{e}"
    end
  end
end
