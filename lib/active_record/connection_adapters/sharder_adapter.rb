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
        disconnect_child_pools!
      end

      def expire
        disconnect_child_pools!
        abstract_instance.expire
      end

      def steal!
        disconnect_child_pools!
        abstract_instance.steal!
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
        connection_pools.each_value(&:disconnect!)
      end

      def child_connection
        connection_pools[database_name].connection
      end

      def connection_pools
        @@connection_pools ||= Hash.new do |pools, database_name|
          pools[database_name] = ConnectionAdapters::ConnectionPool.new(
            child_spec(database_name)
          )
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
