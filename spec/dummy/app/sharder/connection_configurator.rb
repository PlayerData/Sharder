# frozen_string_literal: true

class ConnectionConfigurator
  def connection_config(database_name)
    {
      adapter: :postgresql,
      database: database_name
    }.with_indifferent_access
  end
end
