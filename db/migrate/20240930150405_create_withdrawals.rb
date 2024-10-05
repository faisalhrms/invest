class CreateWithdrawals < ActiveRecord::Migration[7.1]
  def change
    create_table :withdrawals do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :withdrawal_type, null: false  # Profit or Referral
      t.string :status, default: 'pending'    # pending, approved, rejected
      t.datetime :processed_at
      t.timestamps
    end
  end
end
