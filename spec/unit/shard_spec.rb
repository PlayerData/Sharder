# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sharder::Shard do
  let(:club_index) { ClubIndex.create!(name: "test") }
  subject(:shard) { club_index.shard }

  it "checks if a shard exists" do
    expect(shard).to_not exist

    shard.create
    expect(shard).to exist

    shard.destroy
    expect(shard).to_not exist
  end

  describe "creating a shard" do
    it "creates ActiveRecord metadata tables" do
      shard.create

      expect ActiveRecord::SchemaMigration.table_exists?
      expect ActiveRecord::InternalMetadata.table_exists?
    end

    it "loads the correct schema for the group" do
      shard.create
      shard.switch do
        expect ActiveRecord::Base.connection.table_exists?("staffs")
      end
    end

    it "records all migrations of the loaded schema" do
      shard.create
      shard.switch do
        expect ActiveRecord::SchemaMigration.exists?(version: 20_180_121_174_053)
        expect ActiveRecord::SchemaMigration.exists?(version: 20_180_121_173_910)
      end
    end
  end

  describe "destroying a shard" do
    it "removes the shard, even if we have already connected to it" do
      shard.create

      shard.switch { Staff.create!(name: "Test") }

      shard.destroy
    end
  end
end
