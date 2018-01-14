# frozen_string_literal: true

require "active_record"

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
      ActiveRecord::Base.connection.database_name = database_name
      yield
    ensure
      ActiveRecord::Base.connection.database_name = nil
    end
  end
end
