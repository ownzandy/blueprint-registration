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

ActiveRecord::Schema.define(version: 20161213032605) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.integer  "semester_id"
    t.integer  "active",        default: 1
    t.string   "form_ids",      default: [],              array: true
    t.string   "form_names",    default: [],              array: true
    t.string   "form_routes",   default: [],              array: true
    t.string   "mailchimp_ids", default: [],              array: true
    t.integer  "event_type"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["semester_id"], name: "index_events_on_semester_id", using: :btree
  end

  create_table "judges", force: :cascade do |t|
    t.integer "person_id"
    t.integer "event_id"
    t.string  "skills",    default: [], array: true
    t.string  "slack_id"
    t.index ["event_id"], name: "index_judges_on_event_id", using: :btree
    t.index ["person_id"], name: "index_judges_on_person_id", using: :btree
  end

  create_table "mentors", force: :cascade do |t|
    t.integer "person_id"
    t.integer "event_id"
    t.string  "skills",       default: [], array: true
    t.string  "slack_id"
    t.string  "track"
    t.integer "status",       default: 0
    t.string  "benefits",     default: [], array: true
    t.string  "organization"
    t.string  "position"
    t.string  "department"
    t.string  "role"
    t.string  "custom",       default: [], array: true
    t.index ["event_id"], name: "index_mentors_on_event_id", using: :btree
    t.index ["person_id"], name: "index_mentors_on_person_id", using: :btree
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
  end

  create_table "organizers", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "event_id"
    t.string   "slack_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_organizers_on_event_id", using: :btree
    t.index ["person_id"], name: "index_organizers_on_person_id", using: :btree
  end

  create_table "participants", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "event_id"
    t.integer  "team_id"
    t.integer  "status",          default: 0
    t.integer  "graduation_year"
    t.integer  "over_eighteen"
    t.integer  "attending"
    t.string   "major"
    t.string   "school"
    t.string   "website"
    t.string   "resume"
    t.string   "github"
    t.string   "travel"
    t.string   "portfolio"
    t.string   "skills",          default: [],              array: true
    t.string   "custom",          default: [],              array: true
    t.string   "slack_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "track"
    t.string   "benefits",        default: [],              array: true
    t.index ["event_id"], name: "index_participants_on_event_id", using: :btree
    t.index ["person_id"], name: "index_participants_on_person_id", using: :btree
    t.index ["team_id"], name: "index_participants_on_team_id", using: :btree
  end

  create_table "people", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.string   "email"
    t.string   "phone"
    t.string   "form_id",                default: [],              array: true
    t.string   "submit_date",            default: [],              array: true
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "password"
    t.string   "temp_password"
    t.datetime "temp_password_datetime"
    t.string   "session_token"
    t.string   "ethnicity"
    t.string   "dietary_restrictions",   default: [],              array: true
    t.string   "emergency_contacts"
    t.string   "size"
  end

  create_table "projects", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "title"
    t.string   "api_prize",      default: [],              array: true
    t.string   "website_url"
    t.string   "submission_url"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["team_id"], name: "index_projects_on_team_id", using: :btree
  end

  create_table "semesters", force: :cascade do |t|
    t.integer  "season"
    t.integer  "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "speakers", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "event_id"
    t.string   "topic",        default: [],              array: true
    t.string   "description",  default: [],              array: true
    t.datetime "date",         default: [],              array: true
    t.string   "slack_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "position"
    t.string   "organization"
    t.string   "department"
    t.string   "role"
    t.string   "custom",       default: [],              array: true
    t.index ["event_id"], name: "index_speakers_on_event_id", using: :btree
    t.index ["person_id"], name: "index_speakers_on_person_id", using: :btree
  end

  create_table "sponsors", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "event_id"
    t.integer  "sponsorship_tier"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["event_id"], name: "index_sponsors_on_event_id", using: :btree
  end

  create_table "teams", force: :cascade do |t|
    t.integer "event_id"
    t.integer "team_leader"
    t.index ["event_id"], name: "index_teams_on_event_id", using: :btree
  end

  create_table "volunteers", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "event_id"
    t.integer  "hours",      default: 0
    t.string   "times",      default: [],              array: true
    t.string   "custom",     default: [],              array: true
    t.string   "slack_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "status",     default: 0
    t.string   "benefits",   default: [],              array: true
    t.index ["event_id"], name: "index_volunteers_on_event_id", using: :btree
    t.index ["person_id"], name: "index_volunteers_on_person_id", using: :btree
  end

end
