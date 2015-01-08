class EclipseApp
  def self.poll_jobs_feed
    puts '- BEGIN poll_jobs_feed'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'eclipse')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host
      parse_jobs
    end

    puts '- END poll_jobs_feed'
  end

  def self.parse_jobs
    @job_data = get_xml
    jobs = @job_data.xpath("//item")
    
    jobs[0..5].each do |job|
      job_payload = Hash.new
      # GET WHAT WE CAN FROM XML
      # Rails.logger.info "--- job.xpath('author') = #{job.xpath("author").inspect}"
      job_payload['job[job_title]'] = job.xpath('title').text.strip
      app_email = job.xpath('author').text.strip.split.first.strip
      job_payload['job[application_email]'] = app_email
      job_payload['job[discipline]'] = job.xpath('category').text.strip
      job_payload['job[created_at]'] = job.xpath('pubDate').text.strip

      # SCRAPE WEB PAGE
      page_url = job.xpath("link").text.strip.gsub('www.austinandrew.co.uk', 'austinandrew.recruitment-websites.co.uk')
      page = Nokogiri::XML(open(page_url))
      job_payload['job[job_reference]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_RefNo').text.strip
      job_payload['job[location]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Location').text.strip
      job_payload['job[job_type]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_LengthofContract').text.strip
      job_payload['job[salary_free]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Salary').text.strip
      salary_val = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_Salary').text.strip.tr('£,', '')
      job_payload['job[salary_low]'] = job_payload['job[salary_high]'] = salary_val
      job_payload['job[job_description]'] = page.css('#ctl00_ctl00_ctl00_ctl00_cphRoot_cphSite_cphLC_cphC_lblVacancy_JobDescription').text.strip
      Rails.logger.info "--- job_payload = #{job_payload.inspect}"

      # job_payload["job[job_type]"] = "unspecified"
      # job_payload["job[api_key]"] = @key.api_key

      # # Map the general attributes onto the payload
      # attribute_mapping.each do |k,v|
      #   child = job.xpath("#{k}")
      #   puts child.text.strip if child.text.present? and v == 'discipline'
      #   job_payload["job[#{v}]"] = child.text.strip if child.text.present?
      # end

      # lang_nodes = job.xpath("languages")
      # languages = lang_nodes.text.gsub(';', ',')
      # job_payload["job[extra][skills]"] = languages

      # # Expiry = date + 30 days
      # begin
      #   date = Date.parse(job_payload["job[created_at]"])
      #   job_payload["job[expiry_date]"] = date + 365.days
      # rescue Exception => e
      #   puts "[WARN] #{e}"
      #   job_payload["job[expiry_date]"] = Date.today + 365.days
      # end

      # # Map the job location, drop empties and comma-join:
      # addr_nodes = job.xpath("city | country")
      # job_location = addr_nodes.map(&:text).reject(&:empty?).join(', ')
      # job_payload["job[job_location]"] = job_location if job_location.present?

      # post_payload(job_payload) unless job_payload["job[discipline]"].blank?
    end
  end

private
  def self.get_xml
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    doc = Nokogiri::XML(open(settings.settings["Feed URL"]))
  end

  def self.post_payload(payload)
    net = Net::HTTP.new(@key.host, 80)
    request = Net::HTTP::Post.new("/api/v1/jobs.json")
    request.set_form_data( payload )
    net.read_timeout = net.open_timeout = 10

    begin
      response = net.start do |http|
        http.request(request)
      end

      puts "#{response.code} - #{response.read_body}"
      return response.code.to_i == 200
    rescue Exception => e
      puts "[FAIL] http.request failed to post payload: #{e}"
    end
  end

  def self.attribute_mapping
     {
      title: 'job_title',
      referencenumber: 'job_reference',
      url: 'application_url',
      description: 'job_description',
      salary: 'salary_free',
      jobtype: 'job_type',
      category: 'discipline',
      function: 'job_functions',
      date: 'created_at'
    }
  end
end