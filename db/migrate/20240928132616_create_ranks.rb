class CreateRanks < ActiveRecord::Migration[7.1]
  def change
    create_table :ranks do |t|
      t.string :name, null: false
      t.decimal :minimum_deposit, precision: 15, scale: 2, default: 0.0
      t.decimal :profit_percentage, precision: 5, scale: 2,  default: 0.0
      t.timestamps
    end
  end
end
