# frozen_string_literal: true

# We replace ActiveRecord::Migrator with Sharder::Migrator in sharder/extensions
# This gives us access to Rails' original migrator
RailsMigrator = ActiveRecord::Migrator.clone

class Sharder
  module Migrator
    class NoShardGroupSpecifiedError < StandardError
      def to_s
        "
        Each migration must specify a shard group so sharder knows which databases
        the migrations should run on.

        class Migration < ActiveRecord::Migration[5.1]
          self.shard_group = :default
        end
        "
      end
    end

    attr_reader :default_shard_migrator

    delegate :current_version, :current_migration, :current, :pending_migrations, to: :default_shard_migrator

    def initialize(direction, migrations, target_version = nil)
      @direction = direction
      @migrations = migrations
      @target_version = target_version

      @default_shard_migrator = RailsMigrator.new(direction, migrations, target_version)

      validate(@migrations)
    end

    def run
      on_each_shard do |shard_group|
        shard_migrations = @migrations.select { |m| m.shard_group == shard_group }
        RailsMigrator.new(@direction, shard_migrations, @target_version).run
      end

      record_default_version_state_after_migrating
    end

    def migrate
      on_each_shard do |shard_group|
        shard_migrations = @migrations.select { |m| m.shard_group == shard_group }
        RailsMigrator.new(@direction, shard_migrations, @target_version).migrate
      end

      record_default_version_state_after_migrating
    end

    private

    def sharder_connection
      ActiveRecord::Base.establish_connection.connection
    end

    def configurator
      sharder_connection.configurator
    end

    def validate(migrations)
      raise NoShardGroupSpecifiedError if migrations.select { |m| m.shard_group.nil? }.any?
    end

    def on_each_shard
      configurator.shard_groups.map do |shard_group|
        shards = configurator.database_names_for_shard_group(shard_group)
        shards.each do |shard|
          Sharder.using(shard) do
            yield shard_group
          end
        end
      end
    end

    def record_default_version_state_after_migrating
      @migrations.each do |migration|
        if @direction == :down
          ActiveRecord::SchemaMigration.where(version: migration.version.to_s).delete_all
        else
          next if migration.shard_group == :default
          ActiveRecord::SchemaMigration.create!(version: migration.version.to_s)
        end
      end
    end
  end
end
