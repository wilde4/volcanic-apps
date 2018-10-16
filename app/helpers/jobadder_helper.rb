module JobadderHelper
  class << self

    def authentication_urls
      {
          authorize: 'https://id.jobadder.com/connect/authorize',
          token: 'https://id.jobadder.com/connect/token'
      }
    end

    def temporary_files_dir
      "#{Rails.root.join}/tmp/files"
    end

    def base_urls
      {
          job_adder: 'https://api.jobadder.com/v2',
          volcanic: 'https://www.volcanic.co.uk/api/v1'
      }
    end

    def endpoints
      {
          jobs: '/jobs',
          candidates: '/candidates',
          applications: '/applications',
          users: '/users',
          candidate_custom_fields: '/candidates/fields/custom'
      }
    end

    def callback_url
      (Rails.env.development? || Rails.env.test?) ? 'http://127.0.0.1:3001/jobadder/callback' : "https://#{ENV['DOMAIN_NAME']}/jobadder/callback"
    end

  end
end