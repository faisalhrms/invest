class AddDurationInDaysIn < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :duration_in_days, :float
  end
end
