class AddTaxFieldsToJobBoard < ActiveRecord::Migration
  def change
    add_column :job_boards, :charge_vat, :boolean
    add_column :job_boards, :default_vat_rate, :decimal, :precision => 8, :scale => 2
  end
end
