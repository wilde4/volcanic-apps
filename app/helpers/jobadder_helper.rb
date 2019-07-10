module JobadderHelper
  class << self

    def authentication_urls
      {
        authorize: 'https://id.jobadder.com/connect/authorize',
        token: 'https://id.jobadder.com/connect/token'
      }
    end

    def temporary_files_dir
      "#{Rails.root.join}/tmp"
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
        candidate_custom_fields: '/candidates/fields/custom',
        worktypes: '/worktypes',
        job_boards: '/jobboards'

      }
    end

    def callback_url
      (Rails.env.development? || Rails.env.test?) ? 'http://127.0.0.1:3001/jobadder/callback' : "https://#{ENV['DOMAIN_NAME']}/jobadder/callback"
    end

    def attachment_types
      %w(Resume FormattedResume CoverLetter Screening Check Reference License Other)
    end

    def get_reg_answer_files(reg_answers, ja_setting, key)

      files = []
      attachment_types = JobadderHelper.attachment_types

      if reg_answers.present?
        ja_setting.jobadder_field_mappings.each do |mapping|
          attachment_types.each do |attachment_type|
            if mapping.jobadder_field_name == attachment_type
              reg_answers.each do |reg_answer|
                unless reg_answer[mapping.registration_question_reference].nil?
                  file = {}
                  file['name'] = mapping.registration_question_reference
                  file['url'] = "#{key.protocol}#{key.host}#{reg_answer[mapping.registration_question_reference]}"
                  file['type'] = attachment_type

                  files << file
                end
              end
            end
          end
        end
      end

      return files

    end

  end
end
