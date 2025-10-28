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

ActiveRecord::Schema[8.0].define(version: 2025_10_27_082845) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "mobile"
    t.boolean "status", default: true
    t.string "password_digest"
    t.string "otp_pin"
    t.datetime "otp_sent_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_type"
    t.datetime "deleted_at"
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["reset_password_token"], name: "index_accounts_on_reset_password_token", unique: true
  end

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

  create_table "addresses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.string "address_line1", null: false
    t.string "address_line2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "pincode", null: false
    t.string "country", default: "India", null: false
    t.integer "address_type", default: 0
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "is_default"], name: "index_addresses_on_account_id_and_is_default"
    t.index ["account_id"], name: "index_addresses_on_account_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.bigint "variant_id"
    t.integer "qty"
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id", "variant_id"], name: "index_cart_items_uniqueness", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
    t.index ["variant_id"], name: "index_cart_items_on_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_carts_on_account_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "offer_usages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "offer_id", null: false
    t.datetime "used_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "offer_id"], name: "index_offer_usages_on_account_id_and_offer_id", unique: true
    t.index ["account_id"], name: "index_offer_usages_on_account_id"
    t.index ["offer_id"], name: "index_offer_usages_on_offer_id"
  end

  create_table "offers", force: :cascade do |t|
    t.string "code", null: false
    t.decimal "discount", precision: 10, scale: 2, null: false
    t.decimal "min_order", precision: 10, scale: 2, default: "0.0"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "expires_at"
    t.integer "usage_limit", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "discount_type", default: "percentage", null: false
    t.index ["code"], name: "index_offers_on_code", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.bigint "variant_id"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.string "product_name"
    t.string "variant_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["order_id", "product_id", "variant_id"], name: "index_order_items_on_order_product_variant", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["variant_id"], name: "index_order_items_on_variant_id"
  end

  create_table "order_statuses", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "status", null: false
    t.text "notes"
    t.integer "step_index"
    t.string "user_message"
    t.datetime "estimated_delivery"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_order_statuses_on_created_by_id"
    t.index ["order_id", "created_at"], name: "index_order_statuses_on_order_id_and_created_at"
    t.index ["order_id"], name: "index_order_statuses_on_order_id"
    t.index ["status"], name: "index_order_statuses_on_status"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "shipping_address_id", null: false
    t.bigint "billing_address_id", null: false
    t.string "order_number", null: false
    t.string "status", default: "pending", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "payment_method"
    t.string "payment_status", default: "pending", null: false
    t.text "notes"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.datetime "cancelled_at"
    t.datetime "estimated_delivery"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["billing_address_id"], name: "index_orders_on_billing_address_id"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["shipping_address_id"], name: "index_orders_on_shipping_address_id"
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "product_features", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_features_on_product_id"
  end

  create_table "product_includes", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "item"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_includes_on_product_id"
  end

  create_table "product_specifications", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_specifications_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "sku", null: false
    t.text "description"
    t.text "features"
    t.string "material", null: false
    t.integer "pieces_count", null: false
    t.string "brand"
    t.boolean "is_featured", default: false
    t.boolean "is_new", default: false
    t.integer "views_count", default: 0
    t.bigint "subcategory_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["is_featured"], name: "index_products_on_is_featured"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["subcategory_id"], name: "index_products_on_subcategory_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "product_id", null: false
    t.string "title"
    t.text "comment"
    t.integer "rating"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_reviews_on_account_id"
    t.index ["product_id"], name: "index_reviews_on_product_id"
  end

  create_table "subcategories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
    t.index ["slug"], name: "index_subcategories_on_slug", unique: true
  end

  create_table "subscribes", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "variants", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "sku", null: false
    t.string "size"
    t.string "color"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "original_price", precision: 10, scale: 2
    t.integer "discount_percentage", default: 0
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["sku"], name: "index_variants_on_sku", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "accounts"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "cart_items", "variants"
  add_foreign_key "carts", "accounts"
  add_foreign_key "offer_usages", "accounts"
  add_foreign_key "offer_usages", "offers"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "variants"
  add_foreign_key "order_statuses", "accounts", column: "created_by_id"
  add_foreign_key "order_statuses", "orders"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "addresses", column: "billing_address_id"
  add_foreign_key "orders", "addresses", column: "shipping_address_id"
  add_foreign_key "product_features", "products"
  add_foreign_key "product_includes", "products"
  add_foreign_key "product_specifications", "products"
  add_foreign_key "products", "subcategories"
  add_foreign_key "reviews", "accounts"
  add_foreign_key "reviews", "products"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "variants", "products"
end
