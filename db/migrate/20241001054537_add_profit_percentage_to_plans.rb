class AddProfitPercentageToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :investment_plans, :profit_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :trading_plans, :profit_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :stakings, :profit_percentage, :decimal, precision: 5, scale: 2, default: 0.0
  end
end
