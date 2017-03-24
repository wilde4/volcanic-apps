require 'shoryuken'

config_file = Rails.root.join('config', 'shoryuken-aws.yml')

unless Rails.env.test?
  Shoryuken::EnvironmentLoader.load(config_file: config_file)
  Rails.logger.info "Shoryuken loaded with options #{Shoryuken.options}"
end