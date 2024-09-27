class AddRankInPurchase < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :rank, :string, default: "NO RANK!"
  end
end
