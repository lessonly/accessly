require "test_helper"
require_relative File.expand_path("../../../lib/generators/accessly/install/install_generator", __FILE__)

class Accessly::InstallGeneratorTest < ::Rails::Generators::TestCase
  tests Accessly::Generators::InstallGenerator
  destination File.expand_path("../../tmp", File.dirname(__FILE__))

  setup do
    run_generator
  end

  Minitest.after_run do
    FileUtils.rm_rf(destination_root)
  end

  test "generates migrations" do
    migration1 = migration_file_name("db/migrate/create_permitted_actions.rb")
    migration2 = migration_file_name("db/migrate/create_permitted_action_on_objects")
    bad_migration = migration_file_name("db/migrate/accessly_not_exist")

    refute_nil(migration1)
    refute_nil(migration2)
    assert_nil(bad_migration)
  end
end
