class CreateClientVatRates < ActiveRecord::Migration
  def change
    create_table :client_vat_rates do |t|
      t.string :client_token
      t.decimal :vat_rate, :precision => 8, :scale => 2
    end
  end
end
