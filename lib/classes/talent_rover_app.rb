# TalentRoverApp.poll_jobs_feed
class TalentRoverApp
  def self.poll_jobs_feed
    puts '- BEGIN poll_jobs_feed'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'talent_rover')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host
      settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
      unless settings.present? && settings.settings.present? && settings.settings["Feed URL"].present?
        puts "No Feed URL configured - skipping"
        next
      end
      @job_data = get_xml
      if @job_data
        parse_jobs
        prune_jobs if get_prune_jobs_setting
      else
        puts "No data received from feed!"
      end
    end

    puts '- END poll_jobs_feed'
  end

  def self.parse_jobs
    jobs = @job_data.xpath("//job")

    # Has a Posting Language been defined?
    posting_language = get_posting_language.downcase

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

      # Replace job_payload[description + title] if language present:
      job_post_langs = job.xpath("postinglanguage").text
      job_post_langs = job_post_langs.downcase.split(';') if job_post_langs.present?

      if posting_language.present? 
        if job_post_langs.include?(posting_language)
          job_payload["job[job_title]"] = job.xpath("#{posting_language}title").text
          job_payload["job[job_description]"] = job.xpath("#{posting_language}clientdesc").text
        else
          next
        end
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

  def self.prune_jobs
    puts '- START pruning jobs'
    jobs = @job_data.xpath("//job")
    posting_language = get_posting_language.downcase

    live_job_refs = []
    jobs.each do |job|
      job_post_langs = job.xpath("postinglanguage").text
      job_post_langs = job_post_langs.downcase.split(';') if job_post_langs.present?

      if posting_language.present? 
        if job_post_langs.include?(posting_language)
          live_job_refs << job.xpath("referencenumber").text.strip if job.xpath("referencenumber").text.present?
        end
      else
        # ADD ALL JOBS SO THEY ARE NOT PURGED
        live_job_refs << job.xpath("referencenumber").text.strip if job.xpath("referencenumber").text.present?
      end
    end
    response = HTTParty.get("http://#{@key.host}/api/v1/jobs/job_references.json")
    
    current_job_refs = JSON.parse response.read_body
    current_job_refs.each do |job|
      unless live_job_refs.include? job['job_reference']
        begin
          payload = {}
          payload["job[api_key]"] = @key.api_key
          payload["job[job_reference]"] = job['job_reference']
          response = HTTParty.post("https://#{@key.host}/api/v1/jobs/expire.json", { body: payload })
          puts "#{response.code} - #{response.read_body}"
        rescue Exception => e
          puts "[FAIL] http.request failed to post Expire payload: #{e}"
        end
      end
    end
  end

private
  def self.get_xml
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    doc = Nokogiri::XML(open(settings.settings["Feed URL"]))
  rescue StandardError => e
    false
  end

  def self.get_posting_language
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    settings.settings["Posting Language"] || ""
  end

  def self.get_prune_jobs_setting
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    settings.settings["Prune Jobs"] && settings.settings["Prune Jobs"].downcase == "yes"
  end

  def self.post_payload(payload)
    # net = Net::HTTP.new(@key.host)
    # request = Net::HTTP::Post.new("/api/v1/jobs.json")
    # request.set_form_data( payload )
    # net.read_timeout = net.open_timeout = 10

    begin
      # response = net.start do |http|
      #   http.request(request)
      # end

      response = HTTParty.post("https://#{@key.host}/api/v1/jobs.json", { body: payload })

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
      lastmodifieddate: 'created_at'
    }
  end
end