# frozen_string_literal: true

module ActiveRecord
  module Tasks
    class SharderDatabaseTasks
      def initialize(configuration)
        @task_database_configuration = configuration
      end

      def create
        DatabaseTasks.create(connection_config)
      end

      def drop
        sharder_connection.disconnect_pool!(database_name)
        DatabaseTasks.drop(connection_config)
      end

      def purge
        sharder_connection.disconnect_pool!(database_name)
        DatabaseTasks.purge(connection_config)
      end

      private

      def database_name
        @task_database_configuration["database"]
      end

      def sharder_connection
        Rails.application.initialize! unless Rails.application.initialized?

        ActiveRecord::Base.establish_connection.connection
      end

      def connection_config
        @connection_config ||= begin
          sharder_connection.connection_config(database_name)
        end
      end
    end

    DatabaseTasks.register_task(/sharder/, SharderDatabaseTasks)
  end
end
