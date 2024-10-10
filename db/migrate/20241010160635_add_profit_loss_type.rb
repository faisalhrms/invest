class AddProfitLossType < ActiveRecord::Migration[7.1]
  def change
    add_column :profits, :profit_loss_type, :string
  end
end
