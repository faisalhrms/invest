class AddReferralCommissionAndDepositToTransactionHistories < ActiveRecord::Migration[7.1]
  def change
    add_column :transaction_histories, :referral_commission_id, :integer
    add_column :transaction_histories, :deposit_id, :integer
  end
end
