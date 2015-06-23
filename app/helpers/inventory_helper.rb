module InventoryHelper

  def currency_to_symbol(currency)
    case currency
    when "EUR"
      return "€"
    when "USD"
      return "$"
    else
      return "£"
    end
  end

end