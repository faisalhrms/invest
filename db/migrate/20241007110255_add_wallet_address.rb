class AddWalletAddress < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :wallet_address ,:string
  end
end
