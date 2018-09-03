class CreateJobadderRequestBodies < ActiveRecord::Migration
  def change
    create_table :jobadder_request_bodies do |t|
      t.string  :request_type
      t.string   :endpoint
      t.string   :name
      t.text     :json
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end