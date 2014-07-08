# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131203194137) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "items", force: true do |t|
    t.integer  "order_id"
    t.integer  "item_number"
    t.string   "file_1"
    t.string   "file_2"
    t.string   "product_code"
    t.string   "product_name"
    t.integer  "quantity"
    t.string   "paper"
    t.string   "trim_size"
    t.string   "final_size"
    t.string   "score"
    t.string   "color_process"
    t.boolean  "uv_coating"
    t.boolean  "drill"
    t.string   "pick_out_item"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["order_id"], name: "index_items_on_order_id", using: :btree

  create_table "orders", force: true do |t|
    t.string   "order_number"
    t.integer  "item_count"
    t.string   "status"
    t.string   "ship_method"
    t.string   "ship_to_full_name"
    t.string   "ship_to_first_name"
    t.string   "ship_to_last_name"
    t.string   "ship_to_company"
    t.string   "ship_to_addr1"
    t.string   "ship_to_addr2"
    t.string   "ship_to_city"
    t.string   "ship_to_state"
    t.string   "ship_to_zip"
    t.string   "ship_to_phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "order_created"
    t.boolean  "date_processed",     default: false
  end

end
