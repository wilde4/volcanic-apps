class AddExistingCandidateRegistrationsOnlyToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :existing_candidate_registrations_only, :boolean, default: false
  end
end
