class CreateStakings < ActiveRecord::Migration[7.1]
  def change
    create_table :stakings do |t|
      t.string "name"
      t.text "description"
      t.string "price"
      t.string "slug", default: ""
      t.boolean "is_active", default: false
      t.timestamps
    end
  end
end
