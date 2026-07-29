class AddRestoredTransactionIdToRubyNativePurchaseIntents < ActiveRecord::Migration[7.1]
  def change
    add_column :ruby_native_purchase_intents, :restored_transaction_id, :string
  end
end
