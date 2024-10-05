class AddColumnsInPlanType < ActiveRecord::Migration[7.1]
  def change
    add_column :withdrawals, :investment_plan_id, :integer
    add_column :withdrawals, :trading_plan_id, :integer
    add_column :withdrawals, :staking_id, :integer
  end
end
