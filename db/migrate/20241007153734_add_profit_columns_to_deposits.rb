class AddProfitColumnsToDeposits < ActiveRecord::Migration[7.1]
  def change
    add_column :deposits, :calculated_profit, :decimal, precision: 15, scale: 2, default: 0.0  # Store the calculated profit
    add_column :deposits, :profit_eligible, :boolean, default: false  # Indicates whether the profit is eligible for withdrawal
  end
end
