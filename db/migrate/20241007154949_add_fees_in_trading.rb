class AddFeesInTrading < ActiveRecord::Migration[7.1]
  def change
    add_column :trading_plans, :deduction_fee, :integer
  end
end
