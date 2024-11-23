class AddAddColumnsInRanks < ActiveRecord::Migration[7.1]
  def change
    add_column :ranks, :monthly_salary, :float
    add_column :ranks, :referral_percentage, :float
  end
end
