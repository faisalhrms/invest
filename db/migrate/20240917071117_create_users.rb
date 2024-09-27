class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string "email"
      t.string "mobile"
      t.string "cnic"
      t.string "address"
      t.string "password_digest"
      t.string "full_name", default: "System User"
      t.string "user_type", default: "Employee"
      t.boolean "is_active", default: false
      t.boolean "is_logged_in", default: false
      t.integer "role_id"
      t.string "otp"
      t.string "authentication_token"
      t.string "avatar_file_name"
      t.integer "avatar_file_size"
      t.string "avatar_content_type"
      t.datetime "avatar_updated_at"
      t.boolean "target", default: false
      t.datetime "otp_expires_at"
      t.timestamps
    end
  end
end
