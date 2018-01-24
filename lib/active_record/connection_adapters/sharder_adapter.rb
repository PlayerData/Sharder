# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class SharderAdapter
      include ActiveSupport::Callbacks
      define_callbacks :checkout, :checkin

      ADAPTER_NAME = "Sharder"

      attr_writer :database_name

      delegate :connection_config, to: :configurator

      attr_accessor :pool
      attr_reader :abstract_instance
      delegate :lease, :in_use?, :owner, :lock, to: :abstract_instance

      def initialize(connection, logger = nil, config = {})
        super()

        @connection = connection.with_indifferent_access
        @abstract_instance = ActiveRecord::ConnectionAdapters::AbstractAdapter.new(connection, logger, config)
      end

      def adapter_name
        ADAPTER_NAME
      end

      def database_name
        return @connection[:database] if @database_name == :default
        @database_name || @connection[:database]
      end

      def configurator
        @configurator ||= @connection[:connection_configurator].constantize.new
      end

      def database_exists?
        child_connection
      rescue ActiveRecord::NoDatabaseError
        false
      else
        true
      end

      def disconnect_pool!(database_name)
        pool = connection_pools[database_name]
        pool.automatic_reconnect = false
        pool.disconnect!
        connection_pools.delete(database_name)
      end

      def disconnect!
        ActiveSupport::Notifications.instrument "disconnect.sharder" do
          disconnect_child_pools!
        end
      end

      def expire
        ActiveSupport::Notifications.instrument "expire.sharder" do
          disconnect_child_pools!
          abstract_instance.expire
        end
      end

      def steal!
        ActiveSupport::Notifications.instrument "steal.sharder" do
          disconnect_child_pools!
          abstract_instance.steal!
        end
      end

      def method_missing(method_name, *arguments, &block)
        return super unless respond_to_missing?(method_name, true)
        child_connection.send(method_name, *arguments, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        child_connection.respond_to?(method_name, include_private)
      end

      private

      def disconnect_child_pools!
        ActiveSupport::Notifications.instrument "disconnect_child_pools.sharder" do
          connection_pools.each_value(&:disconnect!)
        end
      end

      def child_connection
        ActiveSupport::Notifications.instrument "child_connection.sharder", database_name: database_name do
          connection_pools[database_name].connection
        end
      end

      def connection_pools
        @connection_pools ||= Concurrent::Hash.new do |pools, database_name|
          ActiveSupport::Notifications.instrument "pool_initialization.sharder", database_name: database_name do
            pools[database_name] = ConnectionAdapters::ConnectionPool.new(
              child_spec(database_name)
            )
          end
        end
      end

      def child_spec(database_name)
        spec = connection_config(database_name)

        path_to_adapter = "active_record/connection_adapters/#{spec[:adapter]}_adapter"
        require path_to_adapter

        adapter_method = "#{spec[:adapter]}_connection"
        ConnectionSpecification.new(database_name, spec, adapter_method)
      end
    end
  end
end
