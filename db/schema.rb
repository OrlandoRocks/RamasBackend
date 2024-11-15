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

ActiveRecord::Schema[7.0].define(version: 2024_08_02_005105) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "code"
    t.string "full_name"
    t.string "identification_card"
    t.string "rfc"
    t.string "address"
    t.string "colony"
    t.string "zip_code"
    t.string "phone_number"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "assignee"
    t.string "email"
    t.date "birthday"
    t.string "nationality"
    t.string "civil_status"
    t.string "spouse"
    t.boolean "economic_dependants"
    t.boolean "home_owner"
    t.string "occupation"
    t.string "company"
    t.string "company_address"
    t.string "company_phone"
    t.decimal "monthly_income"
    t.decimal "monthly_expenses"
    t.text "comments"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "land_id", null: false
    t.date "contract_date"
    t.string "contract_type"
    t.decimal "down_payment"
    t.decimal "monthly_payment"
    t.decimal "yearly_payment"
    t.float "months"
    t.decimal "penalty_interest"
    t.decimal "extraordinary_payment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_contracts_on_client_id"
    t.index ["land_id"], name: "index_contracts_on_land_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "residential_id", null: false
    t.bigint "user_id", null: false
    t.string "account"
    t.string "department"
    t.string "expense_type"
    t.string "comments"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["residential_id"], name: "index_expenses_on_residential_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "lands", force: :cascade do |t|
    t.bigint "residential_id", null: false
    t.string "land_code"
    t.string "address"
    t.string "block"
    t.float "size"
    t.decimal "price"
    t.string "house_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["residential_id"], name: "index_lands_on_residential_id"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.date "payment_date"
    t.string "payment_type"
    t.text "comments"
    t.string "image_url"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contract_id"
    t.index ["contract_id"], name: "index_payments_on_contract_id"
  end

  create_table "residentials", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.decimal "cost"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_residentials_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "password_digest", default: "", null: false
    t.string "name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "role_id", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "contracts", "clients"
  add_foreign_key "contracts", "lands"
  add_foreign_key "expenses", "residentials"
  add_foreign_key "expenses", "users"
  add_foreign_key "lands", "residentials"
  add_foreign_key "payments", "contracts"
  add_foreign_key "residentials", "users"
  add_foreign_key "users", "roles"
end
