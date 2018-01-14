# frozen_string_literal: true

module ActiveRecord
  class Base
    def self.sharder_connection(config)
      ActiveRecord::ConnectionAdapters::SharderAdapter.new(config)
    end
  end
end

ActiveRecord::Migration.prepend(Sharder::Migration)
ActiveRecord::MigrationProxy.prepend(Sharder::MigrationProxy)
ActiveRecord::Migrator.prepend(Sharder::Migrator)
