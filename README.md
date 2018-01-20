# Sharder

Dynamic Database Sharding for Rails

[![Build Status](https://travis-ci.org/PlayerData/sharder.svg?branch=master)](https://travis-ci.org/PlayerData/sharder)

At PlayerData we have multiple different database schemas, some of which are
related to particular tenants, and some of which aren't.

Initially, we used [Octopus](https://github.com/thiagopradi/octopus), but Octopus
requires knowledge of all databases when the application boots.

While [Apartment](https://github.com/influitive/apartment) does handle dynamic
connections, it doesn't allow different schema definitions for different databases.

Inspired by Octopus' proxy model, Sharder defines an ActiveRecord adapter that proxies through to a child adapter. This allows us to (with few changes) have separate schemas for each of our database groups.
However, Sharder configures child connections on demand without requiring prior knowledge of all shards, allowing us to create and destroy databases at run time.

Sharder is still in early stages of development, and will likely change
significantly as we discover bugs and usability issues as we use it in our application. Use at your own risk!

## Installation

1)
  Add this line to your application's Gemfile:
  ```ruby
  gem 'sharder', git: 'https://github.com/playerdata/sharder'
  ```

2)
  Execute:
  ```bash
  $ bundle
  ```

3)
  Tell Rails to use sharder as the database adapter. Set `database` to the default database for your application

  ```yaml
  default: &default
    adapter: sharder
    connection_configurator: ConnectionConfigurator
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

  development:
    <<: *default
    database: sharder_dummy_development

  test:
    <<: *default
    database: sharder_dummy_test
  ```

4)
  Define your connection configurator. See `spec/dummy/app/sharder/connection_configurator.rb` for the latest api

  ```ruby
  # app/sharder/connection_configurator.rb

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
  ```

## Usage

### Switching databases

```ruby
Sharder.using("database_name") do
  model = SomeModel.create!
  model.reload
  # etc...
end
```

### The `Sharder::Database` model

Sharder defines a `Sharder::Database` model that aids in the creation and destruction of tenant databases.

See `spec/dummy/app/models/club_index` for an example.

```ruby
shard_group = :clubs
database = Sharder::Database.new(database_name, shard_group)

# Create a database in the :clubs group, and load the db/schemas/clubs.rb schema
database.create

# Switch to the database
database.switch do
  # Do something in the database
end

# Destroy the database, closing any active connections from this
# application instance
database.destroy
```

### Migrations

When using the Sharder adapter, all migrations must belong to a `shard_group`.

After running `rails g migration`, set the shard group for the migration:

```ruby
class CreateStaffs < ActiveRecord::Migration[5.1]
  #########################
  # Set the shard group:  #
  self.shard_group = :clubs
  #########################

  def change
    create_table :staffs do |t|
      t.string :name

      t.timestamps
    end
  end
end
```

All shards returned by `database_names_for_shard_group` in the configurator will have the migration applied on running `rails db:migrate`. The `schema_migrations` table in the default database will also be updated.

After applying migrations, or when running `rails db:schema:dump`, a sample database from each schema group will be dumped. The default database is dumped to `db/schema.rb` as normal, with other shard groups being dumped to `db/schemas/<shard_group_name>.rb`.

## Contributing

Please ensure that any bug fixes are accompanied by a previously failing test case, and that new features are thoroughly tested.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
