# frozen_string_literal: true

namespace :sharder do
  desc "Explaining what the task does"
  task dump: [:environment] do
    Sharder::SchemaDumper.dump
  end
end

Rake::Task["db:schema:dump"].enhance do
  Rake::Task["sharder:dump"].invoke
end
