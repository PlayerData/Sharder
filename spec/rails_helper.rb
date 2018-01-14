# frozen_string_literal: true

require "rails/all"
require "rspec/rails"

require "dummy/config/environment"

ActiveRecord::Migration.maintain_test_schema!

# set up db
# be sure to update the schema if required by doing
# - cd spec/rails_app
# - rake db:migrate
ActiveRecord::Schema.verbose = false
load "dummy/db/schema.rb" # use db agnostic schema by default
