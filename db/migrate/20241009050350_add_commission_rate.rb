class AddCommissionRate < ActiveRecord::Migration[7.1]
  def change
    add_column :investment_plans, :commission_rate, :float
    add_column :trading_plans, :commission_rate, :float
    add_column :stakings, :commission_rate, :float
  end
end
