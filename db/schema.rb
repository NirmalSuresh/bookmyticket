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

ActiveRecord::Schema[7.1].define(version: 2026_03_06_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "showtime_id", null: false
    t.text "seats"
    t.decimal "total_price"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "razorpay_order_id"
    t.string "razorpay_payment_id"
    t.string "razorpay_signature"
    t.datetime "paid_at"
    t.index ["showtime_id"], name: "index_bookings_on_showtime_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "movies", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "duration"
    t.date "release_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "genre"
    t.string "rating"
    t.string "poster_url"
    t.string "trailer_url"
    t.text "cast"
    t.string "director"
    t.string "language"
  end

  create_table "screens", force: :cascade do |t|
    t.string "name"
    t.integer "capacity"
    t.bigint "theater_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["theater_id"], name: "index_screens_on_theater_id"
  end

  create_table "showtimes", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "theater_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "screen_id", null: false
    t.index ["movie_id"], name: "index_showtimes_on_movie_id"
    t.index ["screen_id"], name: "index_showtimes_on_screen_id"
    t.index ["theater_id"], name: "index_showtimes_on_theater_id"
  end

  create_table "theaters", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bookings", "showtimes"
  add_foreign_key "bookings", "users"
  add_foreign_key "screens", "theaters"
  add_foreign_key "showtimes", "movies"
  add_foreign_key "showtimes", "screens"
  add_foreign_key "showtimes", "theaters"
end
