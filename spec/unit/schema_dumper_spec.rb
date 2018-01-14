# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sharder::SchemaDumper do
  let(:schemas_dir) { Rails.root.join("db", "schemas") }

  it "dumps a schema for each shard group" do
    ClubIndex.create!(name: "Test").database.create
    clubs_schema_path = File.join(schemas_dir, "clubs.rb")

    FileUtils.rm(clubs_schema_path)
    Sharder::SchemaDumper.dump

    dump_contents = File.read(clubs_schema_path)
    expect(dump_contents).to eq club_schema
  end

  it "does not dump a schema for the default schema" do
    default_schema_path = File.join(schemas_dir, "default.rb")
    Sharder::SchemaDumper.dump

    expect(File.exist?(default_schema_path)).to eq false
  end

  def club_schema
    <<~CLUB_SCHEMA
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

      ActiveRecord::Schema.define(version: 20180114122302) do

        create_table "staffs", force: :cascade do |t|
          t.string "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end

      end
    CLUB_SCHEMA
  end
end
