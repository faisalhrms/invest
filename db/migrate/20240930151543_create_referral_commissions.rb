class CreateReferralCommissions < ActiveRecord::Migration[7.1]
  def change
    create_table :referral_commissions do |t|
      t.references :user, null: false, foreign_key: true     # User receiving the commission
      t.references :purchase, null: false, foreign_key: true # Purchase that generated the commission
      t.decimal :amount, precision: 15, scale: 2, default: 0.0
      t.timestamps
    end
  end
end
