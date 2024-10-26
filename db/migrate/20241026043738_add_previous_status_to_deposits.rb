class AddPreviousStatusToDeposits < ActiveRecord::Migration[7.1]
  def change
    add_column :deposits, :previous_status, :string

  end
end
