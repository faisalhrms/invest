class AddTotalProfitToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :total_profit, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :users, :last_profit_calculation, :date

  end
end
