# frozen_string_literal: true

class Sharder
  class Shard
    attr_reader :shard_name, :shard_group

    def initialize(shard_name, shard_group)
      @shard_name = shard_name
      @shard_group = shard_group
    end

    def switch
      Sharder.using(shard_name) do
        yield
      end
    end

    def exists?
      switch { ActiveRecord::Base.connection.shard_exists? }
    end

    def create
      ActiveRecord::Base.connection.create_database(shard_name, "encoding" => "unicode")

      initialize_shard
    end

    def destroy
      Sharder.disconnect_from_shard(shard_name)
      ActiveRecord::Base.connection.drop_database(shard_name)
    end

    protected

    def initialize_shard
      switch do
        ActiveRecord::SchemaMigration.create_table
        ActiveRecord::InternalMetadata.create_table

        with_quiet_schemas do
          load(Rails.root.join("db", "schemas", "#{shard_group}.rb"))
        end
      end
    end

    private

    def with_quiet_schemas
      was_verbose = ActiveRecord::Schema.verbose
      ActiveRecord::Schema.verbose = false

      yield

      ActiveRecord::Schema.verbose = was_verbose
    end
  end
end
