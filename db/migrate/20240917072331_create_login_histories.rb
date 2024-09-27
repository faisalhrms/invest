class CreateLoginHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :login_histories do |t|
      t.integer "user_id"
      t.string "ip_address"
      t.string "browser_name"
      t.boolean "is_active", default: false
      t.timestamps
    end
  end
end
