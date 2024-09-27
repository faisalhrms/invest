class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.boolean "is_active", default: false
      t.string "name"
      t.timestamps
    end
  end
end
