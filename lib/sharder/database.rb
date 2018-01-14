# frozen_string_literal: true

class Sharder
  class Database
    attr_reader :database_name, :shard_group

    def initialize(database_name, shard_group)
      @database_name = database_name
      @shard_group = shard_group
    end

    def switch
      Sharder.using(database_name) do
        yield
      end
    end

    def exists?
      switch { ActiveRecord::Base.connection.database_exists? }
    end

    def create
      ActiveRecord::Base.connection.create_database(database_name, "encoding" => "unicode")

      switch do
        ActiveRecord::SchemaMigration.create_table
        ActiveRecord::InternalMetadata.create_table

        load(Rails.root.join("db", "schemas", "#{shard_group}.rb"))
      end
    end

    def destroy
      ActiveRecord::Base.connection.disconnect_pool!(database_name)
      ActiveRecord::Base.connection.drop_database(database_name)
    end
  end
end
