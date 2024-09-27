class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases do |t|
      t.float :deposit_amount
      t.string :status
      t.boolean :approved, default: false                 # Whether the admin has approved the purchase
      t.string :attachment_file_name                      # Paperclip attachment for the payment proof
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.references :user, foreign_key: true               # The user making the purchase
      t.references :investment_plan, foreign_key: true               # The user making the purchase
      t.references :trading_plan, foreign_key: true               # The user making the purchase
      t.references :staking, foreign_key: true               # The user making the purchase
      t.timestamps
    end
  end
end
