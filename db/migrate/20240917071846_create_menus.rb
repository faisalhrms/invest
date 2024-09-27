class CreateMenus < ActiveRecord::Migration[7.1]
  def change
    create_table :menus do |t|
      t.string "name"
      t.boolean "is_active", default: false
      t.string "slug", default: ""
      t.string "menu_type", default: ""
      t.integer "main_menu_id"
      t.timestamps
    end
  end
end
