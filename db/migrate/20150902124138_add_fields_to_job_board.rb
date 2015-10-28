class AddFieldsToJobBoard < ActiveRecord::Migration
  def change
    add_column :job_boards, :company_number, :string
    add_column :job_boards, :vat_number, :string
    add_column :job_boards, :phone_number, :string
    add_column :job_boards, :address, :text
  end
end
