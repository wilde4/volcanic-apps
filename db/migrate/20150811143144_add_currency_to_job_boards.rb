class AddCurrencyToJobBoards < ActiveRecord::Migration
  def change
    add_column :job_boards, :currency, :string
  end
end
