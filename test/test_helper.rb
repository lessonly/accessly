$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "accessly"
require "bundler/setup"
require "rails"
require "minitest/autorun"
require "minitest/pride"
require "active_record"
require "fixtures/user"
require "fixtures/post"
require "fixtures/group"
require "accessly/permission/grant"
require "accessly/permission/revoke"
require "accessly/models/permitted_action"
require "accessly/models/permitted_action_on_object"
require "database_cleaner"

def prepare_for_tests
  setup_logging
  setup_database_cleaner
  create_test_tables
end

def setup_logging
  require "logger"
  logfile = File.dirname(__FILE__) + "/debug.log"
  ActiveRecord::Base.logger = Logger.new(logfile)
end

def setup_database_cleaner
  DatabaseCleaner.strategy = :truncation
  ActiveSupport::TestCase.send(:setup) do
    DatabaseCleaner.clean
  end
end

def pg_config
  {
    adapter: "postgresql",
    database: "aaa_test",
    pool: 5,
    timeout: 5000
  }
end

def create_test_tables
  schema_file = File.dirname(__FILE__) + "/schema.rb"
  puts "** Loading schema for Postgres"
  ActiveRecord::Base.establish_connection(pg_config)
  load(schema_file) if File.exist?(schema_file)
end

prepare_for_tests
