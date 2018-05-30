# frozen_string_literal: true

class Sharder
  module Migrator
    class NoShardGroupSpecifiedError < StandardError
      def to_s
        "
        Each migration must specify a shard group so sharder knows which shards
        the migrations should run on.

        class Migration < ActiveRecord::Migration[5.1]
          self.shard_group = :default
        end
        "
      end
    end

    private

    def execute_migration_in_transaction(migration, direction)
      shard_group = migration.shard_group
      raise NoShardGroupSpecifiedError unless shard_group

      shard_names = configurator.shard_names_for_shard_group(shard_group)
      shard_names ||= []

      shard_names.each do |shard_name|
        Sharder.using(shard_name) { super }
      end

      return if shard_names.include?(:default)

      record_version_state_after_migrating(migration.version, include_cache: true)
    end

    def record_version_state_after_migrating(version, include_cache: false)
      if down?
        migrated.delete(version) if include_cache
        ActiveRecord::SchemaMigration.where(version: version.to_s).delete_all
      else
        migrated << version if include_cache
        ActiveRecord::SchemaMigration.create!(version: version.to_s)
      end
    end

    def sharder_connection
      ActiveRecord::Base.establish_connection.connection
    end

    def configurator
      sharder_connection.configurator
    end
  end
end
