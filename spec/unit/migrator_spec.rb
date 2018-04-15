# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sharder::Migrator do
  let(:club_index) { ClubIndex.create!(name: "Test") }
  let(:club_index2) { ClubIndex.create!(name: "Test 2") }

  before do
    club_index.database.create
    club_index2.database.create
  end

  it "raises a helpful error message if no shard_group is defined" do
    class ShardNotSetMigration < ActiveRecord::Migration::Current
      def change; end

      def self.version
        50_000_000_000_001
      end
    end

    expect { ActiveRecord::Migrator.new(:up, [ShardNotSetMigration]).migrate }.to(
      raise_error ActiveRecord::Migrator::NoShardGroupSpecifiedError
    )

    expect(ActiveRecord::SchemaMigration.where(version: ShardNotSetMigration.version)).to_not exist
  end

  it "does not error when no database names are returned by the configurator for a migration" do
    class UnknownShardMigration < ActiveRecord::Migration::Current
      self.shard_group = :unknown_group

      def change
        add_column :club_index, :test, :integer
      end

      def self.version
        50_000_000_000_002
      end
    end

    ActiveRecord::Migrator.new(:up, [UnknownShardMigration]).migrate
    expect(ActiveRecord::SchemaMigration.where(version: UnknownShardMigration.version)).to exist

    ActiveRecord::Migrator.new(:down, [UnknownShardMigration]).migrate
    expect(ActiveRecord::SchemaMigration.where(version: UnknownShardMigration.version)).to_not exist
  end

  it "runs and rolls back a migration for the default database" do
    class DefaultShardMigration < ActiveRecord::Migration::Current
      self.shard_group = :default

      def change
        add_column :club_index, :tests, :integer
      end

      def self.version
        50_000_000_000_003
      end
    end

    ActiveRecord::Migrator.new(:up, [DefaultShardMigration]).migrate
    expect(ActiveRecord::SchemaMigration.where(version: DefaultShardMigration.version)).to exist

    ClubIndex.reset_column_information
    ClubIndex.create!(name: "Migration Test", tests: 2).destroy!

    ActiveRecord::Migrator.new(:down, [DefaultShardMigration]).migrate
    expect(ActiveRecord::SchemaMigration.where(version: DefaultShardMigration.version)).to_not exist
    ClubIndex.reset_column_information
    expect { ClubIndex.create!(name: "Migration Test", tests: 2) }.to(
      raise_error ActiveModel::UnknownAttributeError
    )
  end

  describe "migrating sharded databases" do
    class ShardMigration < ActiveRecord::Migration::Current
      self.shard_group = :clubs

      def change
        add_column :staffs, :tests, :integer
      end

      def self.version
        50_000_000_000_004
      end
    end

    it "runs a migration in both directions on each shard" do
      ActiveRecord::Migrator.new(:up, [ShardMigration]).migrate
      expect(ActiveRecord::SchemaMigration.where(version: ShardMigration.version)).to exist

      [club_index, club_index2].each do |index|
        index.database.switch do
          expect(ActiveRecord::SchemaMigration.where(version: ShardMigration.version)).to exist

          Staff.reset_column_information
          Staff.create!(name: "Migration Test", tests: 2)
        end
      end

      ActiveRecord::Migrator.new(:down, [ShardMigration]).migrate
      expect(ActiveRecord::SchemaMigration.where(version: ShardMigration.version)).to_not exist

      [club_index, club_index2].each do |index|
        index.database.switch do
          expect(ActiveRecord::SchemaMigration.where(version: ShardMigration.version)).to_not exist
          Staff.reset_column_information
          expect { Staff.create!(name: "Migration Test", tests: 2) }.to(
            raise_error ActiveModel::UnknownAttributeError
          )
        end
      end
    end

    it "runs migrations on unmigrated shards following an error in migration" do
      club_index.database.switch do
        # Simulate club_index already having migrated
        ShardMigration.migrate(:up)
        ActiveRecord::SchemaMigration.create!(version: ShardMigration.version)
      end

      ActiveRecord::Migrator.new(:up, [ShardMigration]).migrate
      expect(ActiveRecord::SchemaMigration.where(version: ShardMigration.version)).to exist

      [club_index, club_index2].each do |index|
        index.database.switch do
          expect(ActiveRecord::SchemaMigration.where(version: ShardMigration.version)).to exist

          Staff.reset_column_information
          Staff.create!(name: "Migration Test", tests: 2)
        end
      end

      ActiveRecord::Migrator.new(:down, [ShardMigration]).migrate
    end
  end
end
