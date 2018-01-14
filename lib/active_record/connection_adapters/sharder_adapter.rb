# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class SharderAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
      ADAPTER_NAME = "Sharder"

      attr_writer :database_name

      delegate :add_transaction_record, :case_sensitive_modifier, :select_all, :delete, :drop_table, :primary_keys,
               :valid_type?, :insert, :update,
               :type_cast, :to_sql, :quote, :quote_column_name, :quote_table_name, :indexes,
               :quote_table_name_for_assignment, :supports_migrations?, :tables, :table_alias_for,
               :table_exists?, :in_clause_length, :supports_ddl_transactions?, :columns,
               :sanitize_limit, :prefetch_primary_key?, :current_database, :initialize_schema_migrations_table,
               :combine_bind_parameters, :empty_insert_statement_value, :assume_migrated_upto_version,
               :schema_cache, :substitute_at, :internal_string_options_for_primary_key, :lookup_cast_type_from_column,
               :supports_advisory_locks?, :get_advisory_lock, :initialize_internal_metadata_table,
               :release_advisory_lock, :prepare_binds_for_database, :cacheable_query, :column_name_for_operation,
               :prepared_statements, :transaction_state, :create_table, to: :child_connection

      delegate :connection_config, to: :connection_configurator

      def adapter_name
        ADAPTER_NAME
      end

      def database_name
        @database_name || @connection[:database]
      end

      def disconnect_pool!(database_name)
        pool = connection_pools[database_name]
        pool.automatic_reconnect = false
        pool.disconnect!
      end

      private

      def connection_configurator
        @connection_configurator ||= @connection[:connection_configurator].constantize.new
      end

      def child_connection
        connection_pools[database_name].connection
      end

      def connection_pools
        @connection_pools ||= Hash.new do |pools, database_name|
          pools[database_name] = ConnectionHandler.new.establish_connection(
            connection_config(database_name)
          )
        end
      end
    end
  end
end
