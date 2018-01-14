# frozen_string_literal: true

module ActiveRecord
  class Base
    def self.sharder_connection(config)
      ActiveRecord::ConnectionAdapters::SharderAdapter.new(config)
    end
  end
end
