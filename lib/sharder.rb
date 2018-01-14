# frozen_string_literal: true

require "active_record"

require "sharder/config"
require "sharder/extensions"
require "sharder/version"

require "active_record/connection_adapters/sharder_adapter"
require "active_record/tasks/sharder_database_tasks"

class Sharder
  class << self
    def using(database_name)
      ActiveRecord::Base.connection.database_name = database_name
      yield
      ActiveRecord::Base.connection.database_name = nil
    end
  end
end
