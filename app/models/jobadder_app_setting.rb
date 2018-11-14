class JobadderAppSetting < ActiveRecord::Base

  has_many :app_logs, as: :loggable

  has_many :jobadder_field_mappings, dependent: :destroy

  accepts_nested_attributes_for :jobadder_field_mappings, allow_destroy: true, reject_if: proc { |attributes| attributes['jobadder_field_name'].blank? }


end