class AddPurchaseToTransactionHistories < ActiveRecord::Migration[7.1]
  def change
    add_reference :transaction_histories, :purchase, foreign_key: true
  end
end
