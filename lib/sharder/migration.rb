# frozen_string_literal: true

class Sharder
  module Migration
    module ClassMethods
      attr_accessor :shard_group
    end

    def self.prepended(base)
      base.extend Sharder::Migration::ClassMethods
    end
  end
end
