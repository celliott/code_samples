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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130412213261) do

  create_table "habits", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "habits", ["user_id"], :name => "index_habits_on_user_id"

  create_table "habits_users", :force => true do |t|
    t.integer  "habits_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "habits_users", ["habits_id", "user_id"], :name => "index_habits_users_on_habits_id_and_user_id"

  create_table "users", :force => true do |t|
    t.string   "first_name", :limit => 25
    t.string   "last_name",  :limit => 50
    t.string   "email",                    :default => "",    :null => false
    t.string   "password",   :limit => 40
    t.boolean  "temp_pass",                :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  create_table "users_habits", :force => true do |t|
    t.integer  "habits_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "users_habits", ["habits_id", "user_id"], :name => "index_users_habits_on_habits_id_and_user_id"

end
