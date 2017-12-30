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

ActiveRecord::Schema.define(version: 20170816041629) do

  create_table "comments", force: :cascade do |t|
    t.text     "content"
    t.integer  "review_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_comments_on_review_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string   "genre_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "review_genres", force: :cascade do |t|
    t.integer  "genre_id"
    t.integer  "review_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.string   "date_published"
    t.integer  "year"
    t.integer  "writer_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "image"
    t.text     "excerpt"
    t.string   "banner"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.string   "hometown"
    t.string   "email"
    t.string   "password_digest"
    t.boolean  "admin",           default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "provider"
  end

  create_table "writers", force: :cascade do |t|
    t.string   "name"
    t.string   "publication"
    t.text     "bio"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

end
