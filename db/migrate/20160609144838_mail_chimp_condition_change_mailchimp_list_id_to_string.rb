class MailChimpConditionChangeMailchimpListIdToString < ActiveRecord::Migration
  def change
    change_column :mail_chimp_conditions, :mail_chimp_list_id, :string
  end
end
