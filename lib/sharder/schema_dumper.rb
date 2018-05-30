# frozen_string_literal: true

class Sharder
  class SchemaDumper
    class << self
      def dump(connection = ActiveRecord::Base.connection)
        shard_groups = connection.configurator.shard_groups
        shard_groups -= [:default]

        shard_groups.each do |shard_group|
          dump_shard_group(connection, shard_group)
        end
      end

      def dump_shard_group(connection, shard_group)
        schemas_dir = Rails.root.join("db", "schemas")
        FileUtils.mkdir_p(schemas_dir)

        shard_sample = connection.configurator.shard_names_for_shard_group(shard_group).sample
        return unless shard_sample

        shard_schema_file = File.open(File.join(schemas_dir, "#{shard_group}.rb"), "w")

        Sharder.using(shard_sample) do
          ActiveRecord::SchemaDumper.dump(connection, shard_schema_file)
        end

        shard_schema_file.flush
      end
    end
  end
end
