class CreateProfits < ActiveRecord::Migration[7.1]
  def change
    create_table :profits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :purchase, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, default: 0.0

      t.timestamps
    end
  end
end
