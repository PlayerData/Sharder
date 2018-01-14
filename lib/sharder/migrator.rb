# frozen_string_literal: true

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

    private

    def execute_migration_in_transaction(migration, direction)
      shard_group = migration.shard_group
      raise NoShardGroupSpecifiedError unless shard_group

      database_names = configurator.database_names_for_shard_group(shard_group)
      database_names ||= []

      database_names.each do |database_name|
        Sharder.using(database_name) { super }
      end

      return if database_names.include?(:default)

      record_version_state_after_migrating(migration.version)
    end

    def sharder_connection
      ActiveRecord::Base.establish_connection.connection
    end

    def configurator
      sharder_connection.configurator
    end
  end
end
