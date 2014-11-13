class TalentRoverApp
  def self.poll_jobs_feed
    puts '- BEGIN poll_jobs_feed'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'talent_rover')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host
      parse_jobs
    end

    puts '- END poll_jobs_feed'
  end

  def self.parse_jobs
    @job_data = get_xml
    jobs = @job_data.xpath("//job")
    
    jobs.each do |job|
      job_payload = Hash.new
      job_payload["job[job_type]"] = "unspecified"
      job_payload["job[api_key]"] = @key.api_key

      # Map the general attributes onto the payload
      attribute_mapping.each do |k,v|
        child = job.xpath("#{k}")
        puts child.text.strip if child.text.present? and v == 'discipline'
        job_payload["job[#{v}]"] = child.text.strip if child.text.present?
      end

      lang_nodes = job.xpath("languages")
      languages = lang_nodes.text.gsub(';', ',')
      job_payload["job[extra][skills]"] = languages

      # Expiry = date + 30 days
      begin
        date = Date.parse(job_payload["job[created_at]"])
        job_payload["job[expiry_date]"] = date + 365.days
      rescue Exception => e
        puts "[WARN] #{e}"
        job_payload["job[expiry_date]"] = Date.today + 365.days
      end

      # Map the job location, drop empties and comma-join:
      addr_nodes = job.xpath("city | country")
      job_location = addr_nodes.map(&:text).reject(&:empty?).join(', ')
      job_payload["job[job_location]"] = job_location if job_location.present?

      post_payload(job_payload) unless job_payload["job[discipline]"].blank?
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