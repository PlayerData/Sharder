# frozen_string_literal: true

class ConnectionConfigurator
  def connection_config(database_name)
    {
      adapter: :postgresql,
      database: database_name
    }.with_indifferent_access
  end

  def shard_groups
    %i[default clubs]
  end

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
