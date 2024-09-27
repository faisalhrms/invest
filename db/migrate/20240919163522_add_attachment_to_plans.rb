class AddAttachmentToPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plan_transactions do |t|
      t.references :user, foreign_key: true  # Tracks which user bought the plan
      t.references :package, foreign_key: true  # Tracks which plan was purchased
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.datetime :transaction_date  # Date of the transaction
      t.timestamps
    end
  end
end
