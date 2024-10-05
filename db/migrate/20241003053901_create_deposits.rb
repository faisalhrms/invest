class CreateDeposits < ActiveRecord::Migration[7.1]
  def change
    create_table :deposits do |t|
      t.integer   :user_id
      t.decimal "amount", precision: 15, scale: 2, null: false
      t.datetime "processed_at"
      t.string "status"
      t.integer "investment_plan_id"
      t.integer "trading_plan_id"
      t.integer "staking_id"
      t.timestamps
    end
  end
end
