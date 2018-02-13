# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sharder::Database do
  let(:club_index) { ClubIndex.create!(name: "test") }
  subject(:database) { club_index.database }

  it "checks if a shard exists" do
    expect(database).to_not exist

    database.create
    expect(database).to exist

    database.destroy
    expect(database).to_not exist
  end

  describe "creating a shard" do
    it "creates ActiveRecord metadata tables" do
      database.create

      expect ActiveRecord::SchemaMigration.table_exists?
      expect ActiveRecord::InternalMetadata.table_exists?
    end

    it "loads the correct schema for the group" do
      database.create
      database.switch do
        expect ActiveRecord::Base.connection.table_exists?("staffs")
      end
    end

    it "records all migrations of the loaded schema" do
      database.create
      database.switch do
        expect ActiveRecord::SchemaMigration.exists?(version: 20_180_121_174_053)
        expect ActiveRecord::SchemaMigration.exists?(version: 20_180_121_173_910)
      end
    end
  end

  describe "destroying a shard" do
    it "removes the database, even if we have already connected to it" do
      database.create

      database.switch { Staff.create!(name: "Test") }

      database.destroy
    end
  end
end
