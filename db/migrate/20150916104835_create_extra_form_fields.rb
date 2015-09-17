class CreateExtraFormFields < ActiveRecord::Migration
  def change
    create_table :extra_form_fields do |t|
      t.integer :app_dataset_id
      t.string :form
      t.string :param_key
      t.string :label
      t.string :hint


      t.timestamps
    end
  end
end
