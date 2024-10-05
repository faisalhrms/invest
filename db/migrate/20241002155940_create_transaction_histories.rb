class CreateTransactionHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :transaction_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :transaction_type, null: false  # deposit, withdrawal, purchase, refund, etc.
      t.datetime :transaction_date, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :plan_type  # Optional: InvestmentPlan, TradingPlan, etc.
      t.integer :plan_id   # Optional: Reference to specific plan ID
      t.string :status     # Optional: pending, approved, rejected

      t.timestamps
    end
  end
end
