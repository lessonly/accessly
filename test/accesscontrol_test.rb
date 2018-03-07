require "test_helper"

class AccesscontrolTest < Minitest::Test
  def test_can_with_permission
    actor = User.create!

    AccessControl.can?(actor, 1, Post, 5)
  end
end

