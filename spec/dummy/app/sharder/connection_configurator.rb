# frozen_string_literal: true

class ConnectionConfigurator
  # Connection config will be called when attempting to establish
  # a connection with a database this instance of the application has
  # not seen before.
  #
  # This should return a HashWithIndifferentAccess which defines the
  # connection config for a database name.
  def connection_config(database_name)
    {
      adapter: :postgresql,
      database: database_name
    }.with_indifferent_access
  end

  # Shard groups are groups of shards that have identical schemas.
  # This method should return all known shard groups.
  # Any shards that do not belong to a group will not be migrated.
  def shard_groups
    %i[default clubs]
  end

  # For migration purposes, given a shard group name returns all known
  # databases that belong to that group
  def database_names_for_shard_group(shard_group)
    case shard_group
    when :clubs
      club_database_names
    when :default
      [:default]
    end
  end

  private

  def club_database_names
    ClubIndex.all.map(&:database_name)
  end
end
