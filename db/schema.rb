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

ActiveRecord::Schema.define(version: 2019_09_14_100416) do

# Could not dump table "companies" because of following StandardError
#   Unknown type 'boolelan' for column 'target'

  create_table "soks", force: :cascade do |t|
    t.integer "company_id", null: false
    t.date "date", null: false
    t.float "open"
    t.float "high"
    t.float "low"
    t.float "close"
    t.integer "volume", limit: 8
    t.index ["company_id", "date"], name: "index_soks_on_company_id_and_date", unique: true
  end

  create_table "splits", force: :cascade do |t|
    t.integer "sok_id"
    t.float "before"
    t.float "after"
    t.index ["sok_id"], name: "index_splits_on_sok_id"
  end

end
