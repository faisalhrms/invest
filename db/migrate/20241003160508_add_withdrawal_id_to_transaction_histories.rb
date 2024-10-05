class AddWithdrawalIdToTransactionHistories < ActiveRecord::Migration[7.1]
  def change
    add_column :transaction_histories, :withdrawal_id, :integer
  end
end
