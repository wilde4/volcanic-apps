class LeisureJobsImport
  # LeisureJobsImport.import_leisure_jobs
  def self.import_leisure_jobs
    puts '- BEGIN poll_jobs_feed'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'leisure_jobs')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host
      puts "--- @key.host = #{@key.host}"
      parse_leisure_jobs_xml
    end
    puts '- END poll_jobs_feed'
  end

  def self.parse_leisure_jobs_xml
    @job_data = get_xml
    jobs = @job_data.xpath("//job")
      
    jobs[5100..5200].each do |job|
      @job_payload = Hash.new
      @job_payload["job[api_key]"] = @key.api_key

      # GET WHAT WE CAN FROM XML
      @job_payload['job[job_title]'] = job.xpath('Title').text.strip
      @job_payload['job[job_location]'] = job.xpath('LocationDescription').text.strip
      @job_payload['job[salary_free]'] = job.xpath('SalaryDescription').text.strip
      coder = HTMLEntities.new
      @job_payload['job[job_description]'] = coder.decode(job.xpath('Description').text.strip)
      @job_payload['job[expiry_date]'] = job.xpath('EndDate').text.strip
      job_reference = job.xpath('Reference').text.strip.present? ? job.xpath('Reference').text.strip : job.xpath('JobID').text.strip
      @job_payload['job[job_reference]'] = job_reference
      @job_payload['job[application_email]'] = 'hello@leisurejobs.com'

      # SCRAPE WEB PAGE
      page_url = job.xpath("DetailsUrl").text.strip
      puts "page_url = #{page_url}"
      disciplines = []
      begin
        page = Nokogiri::HTML(open(page_url))

        # main_sector = page.xpath("//dl[@class='grid']/div[@class='cf margin-bottom-5'][7]/dd[@class='grid-item three-fifths portable-one-whole palm-one-half']/a[1]").text.strip
        # if main_sector.blank?
        #   main_sector = page.xpath("//dl[@class='grid']/div[@class='cf margin-bottom-5'][5]/dd[@class='grid-item three-fifths portable-one-whole palm-one-half']/a[1]").text.strip
        # end
        # if main_sector.blank?
        #   main_sector = page.xpath("//dl[@class='grid']/div[@class='cf margin-bottom-5'][8]/dd[@class='grid-item three-fifths portable-one-whole palm-one-half']/a[1]").text.strip
        # end
        dt_xpath = page.xpath("//dl[@class='grid']/div[@class='cf margin-bottom-5']/dt[contains(., 'Sector')]")
        # puts "--- dt_xpath = #{dt_xpath}"
        main_sector = dt_xpath.at_xpath("ancestor::div/dd/a[1]").text.strip
        puts "--- main_sector = #{main_sector}"
        # IDENTIFY DISCIPLINE
        case main_sector
        when 'Chef jobs', 'Bar & Pub jobs', 'Restaurant, Catering & Hospitality jobs'
          disciplines << 'hospitality'
        when 'Fitness jobs', 'Sports jobs', 'Spa, Massage & Beauty jobs'
          disciplines << 'health-and-fitness'
        when 'Childcare jobs', 'Commercial Leisure, Attractions & Entertainment jobs', 'Financial & Support jobs', 'Sales & Marketing jobs'
          disciplines << 'commercial-leisure'
        when 'Retail jobs'
          disciplines << 'retail'
        when 'Hotel jobs', 'Ski & Seasonal jobs', 'Temp, Student & Summer jobs', 'Travel & Culture'
          disciplines << 'travel-and-tourism'
        end

        job_type = page.xpath("//dl[@class='grid']/div[@class='cf']/dd[@class='grid-item three-fifths portable-one-whole palm-one-half']/a[1]").text.strip
        puts "--- job_type = #{job_type}"
        case job_type
        when 'Full Time'
          jt = 'full-time'
        when 'Temporary'
          jt = 'temporary'
        when 'Contract'
          jt = 'contract'
        when 'Part Time'
          jt = 'part-time'
        end
        @job_payload['job[job_type]'] = jt

        # SALARY FROM JS
        google_tag_js = page.xpath("//script[5]").text.strip.gsub(/\r\n/, '')
        # puts "--- google_tag_js = #{google_tag_js}"
        match = google_tag_js.match(/\{(.*?)\}/)
        # puts "--- match = #{match.inspect}"
        match_json_string = '{' + match[1].gsub("'", '"') + '}'
        # puts "--- match_json_string = #{match_json_string}"
        match_json = JSON.parse(match_json_string)
        # puts "--- match_json = #{match_json.inspect}"
        salary_band = match_json["Salaryx20Band"]
        salary_band = salary_band.gsub('xa3', '').gsub('x20', '').gsub('x2d', '-')
        # puts "--- salary_band = #{salary_band}"
        salary_low = salary_band.split('-').first.gsub(',', '')
        salary_high = salary_band.split('-').last.gsub(',', '')
        @job_payload['job[salary_low]'] = salary_low unless salary_low == 'Dependentonexperience'
        @job_payload['job[salary_high]'] = salary_high unless salary_low == 'Dependentonexperience'
        puts "--- salary_low = #{salary_low}"
        puts "--- salary_high = #{salary_high}"

        # LeisureJobsImport.import_leisure_jobs
      rescue Exception => e
        puts "--- Failed to open page_url = #{e.inspect}"
        @job_payload = {}
      end

      # app_email = job.xpath('author').text.strip.split.first.strip
      # @job_payload['job[application_email]'] = app_email
      # # @job_payload['job[discipline]'] = job.xpath('category').text.strip
      # disciplines << job.xpath('category').text.strip
      # @job_payload['job[created_at]'] = job.xpath('pubDate').text.strip

      # # SCRAPE WEB PAGE
      # page_url = job.xpath("link").text.strip.gsub('www.austinandrew.co.uk', 'austinandrew.recruitment-websites.co.uk')
      # puts "--- page_url = #{page_url}"
      # begin
      #   page = Nokogiri::HTML(open(page_url))
      #   ref = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_RefNo').text.strip
      #   @job_payload['job[job_reference]'] = ref
      #   # IDENTIFY SUPER DISCIPLINE
      #   ref_acronym = ref.split('-').first
      #   case ref_acronym
      #   when 'SCD'
      #     disciplines << 'Strategy & Corporate Development'
      #   when 'PAC'
      #     disciplines << 'People & Change'
      #   when 'CGV'
      #     disciplines << 'Corporate Governance'
      #   when 'IPE'
      #     disciplines << 'Investment Banking & Private Equity'
      #   end
      #   @job_payload['job[job_location]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Location').text.strip
      #   @job_payload['job[job_type]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_LengthofContract').text.strip
      #   @job_payload['job[salary_free]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Salary').text.strip
      #   salary_val = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Salary').text.strip.tr('£,', '')
      #   @job_payload['job[salary_low]'] = @job_payload['job[salary_high]'] = salary_val
      #   extracted_desc = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_JobDescription').children.to_s
      #   @job_payload['job[job_description]'] = '<p>' + extracted_desc + '</p>'
      #   # EXTRACT CONSULTANT EMAIL ADDRESS
      #   c_email = extracted_desc.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+/)
      #   puts "--- c_email = #{c_email}"
      #   @job_payload['job[contact_email]'] = c_email if c_email.present?
      # rescue Exception => e
      #   puts "--- Failed to open page_url = #{e.inspect}"
      #   @job_payload = {}
      # end

      # @job_payload['job[discipline]'] = disciplines.join(', ')

      # # Expiry = date + 60 days
      # begin
      #   date = Date.parse(@job_payload["job[created_at]"])
      #   @job_payload["job[expiry_date]"] = date + 365.days
      # rescue Exception => e
      #   puts "[WARN] #{e}"
      #   @job_payload["job[expiry_date]"] = Date.today + 365.days
      # end

      @job_payload['job[discipline]'] = disciplines.join(', ')

      # puts "--- @job_payload = #{@job_payload.inspect}"
      post_payload(@job_payload) unless @job_payload["job[discipline]"].blank?
    end
  end
private
  def self.get_xml
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    doc = Nokogiri::XML(open(settings.settings["Feed URL"]))
  end

  def self.post_payload(payload)
    begin
      response = HTTParty.post("http://#{@key.host}/api/v1/jobs.json", { body: payload })

      puts "#{response.code} - #{response.read_body}"
      return response.code.to_i == 200
    rescue Exception => e
      puts "[FAIL] http.request failed to post payload: #{e}"
    end
  end
end
