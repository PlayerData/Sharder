# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "Migration Tasks" do
  let(:club_index) { ClubIndex.create!(name: "Test") }
  let(:club_index2) { ClubIndex.create!(name: "Test 2") }

  before do
    load "spec/dummy/Rakefile"

    club_index.database.create
    club_index2.database.create
  end

  it "runs a migration in both directions on each shard" do
    last_migration_version = ActiveRecord::Base.connection.migration_context.last_migration.version

    run_rake_task("db:rollback")
    expect(ActiveRecord::SchemaMigration.where(version: last_migration_version)).to_not exist

    on_each_shard do
      expect(ActiveRecord::SchemaMigration.where(version: last_migration_version)).to_not exist
    end

    run_rake_task("db:migrate")
    expect(ActiveRecord::SchemaMigration.where(version: last_migration_version)).to exist

    on_each_shard do
      expect(ActiveRecord::SchemaMigration.where(version: last_migration_version)).to exist
    end
  end

  private

  def run_rake_task(name)
    Rake::Task[name].reenable
    Rake::Task[name].invoke
  end

  def on_each_shard
    [club_index, club_index2].each do |index|
      index.database.switch do
        yield
      end
    end
  end
end
