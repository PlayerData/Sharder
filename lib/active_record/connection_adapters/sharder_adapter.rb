# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class SharderAdapter
      ADAPTER_NAME = "Sharder"

      attr_writer :database_name

      delegate :connection_config, to: :configurator

      attr_accessor :pool
      attr_reader :abstract_instance
      delegate :lease, :expire, :steal!, :in_use?, :owner,
               to: :abstract_instance

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

      def disconnect_pool!(database_name)
        pool = connection_pools[database_name]
        pool.automatic_reconnect = false
        pool.disconnect!
        connection_pools.delete(database_name)
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

      def disconnect!
        connection_pools.each_key do |database_name|
          disconnect_pool!(database_name)
        end
      end

      def method_missing(method_name, *arguments, &block)
        return super unless child_connection.respond_to?(method_name)

        child_connection.send(method_name, *arguments, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        child_connection.respond_to?(method_name, include_private)
      end

      private

      def child_connection
        connection_pools[database_name].connection
      end

      def connection_pools
        @@connection_pools ||= Hash.new do |pools, database_name|
          pools[database_name] = ConnectionHandler.new.establish_connection(
            connection_config(database_name)
          )
        end
      end
    end
  end
end
