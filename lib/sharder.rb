# frozen_string_literal: true

require "active_record"
require "concurrent"

require "sharder/version"

require "sharder/migration_proxy"
require "sharder/migration"
require "sharder/migrator"
require "sharder/schema_dumper"
require "sharder/shard"

require "sharder/railtie"
require "sharder/extensions"

require "active_record/connection_adapters/sharder_adapter"
require "active_record/tasks/sharder_database_tasks"

class Sharder
  class << self
    def using(shard_name)
      shard_was = ActiveRecord::Base.connection.shard_name
      ActiveRecord::Base.connection.shard_name = shard_name
      yield
    ensure
      ActiveRecord::Base.connection.shard_name = shard_was
    end

    def disconnect_from_shard(shard_name)
      sharder_pool = ActiveRecord::Base.connection_handler.retrieve_connection_pool("primary")
      sharder_pool.connections.each do |connection|
        next unless connection.is_a? ActiveRecord::ConnectionAdapters::SharderAdapter

        connection.disconnect_pool!(shard_name)
      end
    end
  end
end
