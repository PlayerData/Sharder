# frozen_string_literal: true

require "active_record"
require "concurrent"

require "sharder/version"

require "sharder/database"
require "sharder/migration_proxy"
require "sharder/migration"
require "sharder/migrator"
require "sharder/schema_dumper"

require "sharder/railtie"
require "sharder/extensions"

require "active_record/connection_adapters/sharder_adapter"
require "active_record/tasks/sharder_database_tasks"

class Sharder
  class << self
    def using(database_name)
      database_was = ActiveRecord::Base.connection.database_name
      ActiveRecord::Base.connection.database_name = database_name
      yield
    ensure
      ActiveRecord::Base.connection.database_name = database_was
    end

    def disconnect_from_database(database_name)
      sharder_pool = ActiveRecord::Base.connection_handler.retrieve_connection_pool("primary")
      sharder_pool.connections.each do |connection|
        next unless connection.is_a? ActiveRecord::ConnectionAdapters::SharderAdapter

        connection.disconnect_pool!(database_name)
      end
    end
  end
end
