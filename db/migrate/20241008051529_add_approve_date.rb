class AddApproveDate < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :approve_at, :datetime
  end
end
