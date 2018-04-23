class AddLegalDocumentsToBullhornUsers < ActiveRecord::Migration
  def change
    add_column :bullhorn_users, :legal_documents, :text
  end
end
