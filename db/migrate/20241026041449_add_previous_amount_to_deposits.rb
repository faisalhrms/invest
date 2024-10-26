class AddPreviousAmountToDeposits < ActiveRecord::Migration[7.1]
  def change
    add_column :deposits, :previous_amount, :decimal, precision: 15, scale: 2, default: 0.0

  end
end
