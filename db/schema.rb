# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_09_26_174515) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_streams", force: :cascade do |t|
    t.integer "table_id"
    t.integer "user_id"
    t.string "table_name"
    t.string "ip_address"
    t.string "browser_name"
    t.string "action_name"
    t.date "action_date"
    t.datetime "action_datetime"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "investment_plans", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "price"
    t.string "slug", default: ""
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "login_histories", force: :cascade do |t|
    t.integer "user_id"
    t.string "ip_address"
    t.string "browser_name"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menus", force: :cascade do |t|
    t.string "name"
    t.boolean "is_active", default: false
    t.string "slug", default: ""
    t.string "menu_type", default: ""
    t.integer "main_menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "price"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.boolean "is_index", default: false
    t.boolean "is_create", default: false
    t.boolean "is_view", default: false
    t.boolean "is_edit", default: false
    t.boolean "is_delete", default: false
    t.integer "menu_id"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_create"], name: "index_permissions_on_is_create"
    t.index ["is_delete"], name: "index_permissions_on_is_delete"
    t.index ["is_edit"], name: "index_permissions_on_is_edit"
    t.index ["is_index"], name: "index_permissions_on_is_index"
    t.index ["is_view"], name: "index_permissions_on_is_view"
    t.index ["menu_id"], name: "index_permissions_on_menu_id"
  end

  create_table "plan_transactions", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "package_id"
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "transaction_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.string "deposit_amount"
    t.index ["package_id"], name: "index_plan_transactions_on_package_id"
    t.index ["user_id"], name: "index_plan_transactions_on_user_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.float "deposit_amount"
    t.string "status"
    t.boolean "approved", default: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.bigint "user_id"
    t.bigint "investment_plan_id"
    t.bigint "trading_plan_id"
    t.bigint "staking_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["investment_plan_id"], name: "index_purchases_on_investment_plan_id"
    t.index ["staking_id"], name: "index_purchases_on_staking_id"
    t.index ["trading_plan_id"], name: "index_purchases_on_trading_plan_id"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.boolean "is_active", default: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stakings", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "price"
    t.string "slug", default: ""
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trading_plans", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "price"
    t.string "slug", default: ""
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "referral_id"
    t.string "user_name"
    t.integer "referred_by"
    t.string "mobile_with_country_code"
    t.string "country"
    t.string "rank", default: "NO RANK!"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "plan_transactions", "packages"
  add_foreign_key "plan_transactions", "users"
  add_foreign_key "purchases", "investment_plans"
  add_foreign_key "purchases", "stakings"
  add_foreign_key "purchases", "trading_plans"
  add_foreign_key "purchases", "users"
end
