# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require "dummy/config/environment"

require "spec_helper"
require "rspec/rails"

Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!
