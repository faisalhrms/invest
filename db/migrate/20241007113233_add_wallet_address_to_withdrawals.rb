class AddWalletAddressToWithdrawals < ActiveRecord::Migration[7.1]
  def change
    add_column :withdrawals, :wallet_address, :string
  end
end
