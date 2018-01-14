# frozen_string_literal: true

class Sharder
  module MigrationProxy
    def shard_group
      migration.class.shard_group
    end
  end
end
