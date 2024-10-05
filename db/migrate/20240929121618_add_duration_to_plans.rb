class AddDurationToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :investment_plans, :duration_in_days, :integer
    add_column :trading_plans, :duration_in_days, :integer
    add_column :stakings, :duration_in_days, :integer
  end
end
