require "test_helper"
require "accessly/policy/base"

describe Accessly::Policy::Base do
############
# Accessly::Policy::Base implements an API like this:
# UserPolicy.new(user).view?
# UserPolicy.new(user).view?(other_user)
# UserPolicy.new(user).view_list
#
# It will also implement the following API. Each
# method will simply call the corresponding method
# defined above to keep overriding easy.
# UserPolicy.new(user).can?(:view)
# UserPolicy.new(user).can?(:view, other_user)
# UserPolicy.new(user).list(:view)
############

# TODO: grant
# TODO: revoke
# TODO: Admin checks
# TODO: list (including model_scope)
# TODO: can?

  class UserPolicy < Accessly::Policy::Base

    actions(
      view: 1,
      edit_basic_info: 2,
      change_role: 3,
      destroy: 4
    )

    actions_on_objects(
      view: 1,
      edit_basic_info: 2,
      change_role: 3,
      email: 4
    )

    def self.namespace
      User.name
    end
  end

  class DefaultNamespacePolicy < Accessly::Policy::Base
    actions view: 1
  end

  it "defines action lookup methods" do
    user = User.create!
    other_user = User.create!

    UserPolicy.new(user).view?
    UserPolicy.new(user).edit_basic_info?
    UserPolicy.new(user).change_role?
    UserPolicy.new(user).destroy?

    UserPolicy.new(user).view?(other_user)
    UserPolicy.new(user).edit_basic_info?(other_user)
    UserPolicy.new(user).change_role?(other_user)
    UserPolicy.new(user).email?(other_user)
  end

  it "limits lookup methods to contexts with and without objects appropriately" do
    user = User.create!
    other_user = User.create!

    assert_raises(ArgumentError) do
      UserPolicy.new(user).email?
    end

    assert_raises(ArgumentError) do
      UserPolicy.new(user).destroy?(other_user)
    end
  end

  it "looks up non-object permissions from the Accessly library" do
    user = User.create!

    UserPolicy.new(user).edit_basic_info?.must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    UserPolicy.new(user).edit_basic_info?.must_equal true
  end

  it "caches non-object permission lookups" do
    user = User.create!
    policy = UserPolicy.new(user)

    policy.edit_basic_info?.must_equal false

    permission = Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    policy.edit_basic_info?.must_equal false

    policy = UserPolicy.new(user)
    policy.edit_basic_info?.must_equal true
    permission.destroy!
    policy.edit_basic_info?.must_equal true
  end

  it "looks up object permissions from the Accessly library" do
    user = User.create!
    other_user = User.create!

    UserPolicy.new(user).email?(other_user).must_equal false

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    UserPolicy.new(user).email?(other_user).must_equal true
  end

  it "caches object permission lookups" do
    user = User.create!
    other_user = User.create!
    policy = UserPolicy.new(user)

    policy.email?(other_user).must_equal false

    permission = Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    policy.email?(other_user).must_equal false

    policy = UserPolicy.new(user)
    policy.email?(other_user).must_equal true
    permission.destroy!
    policy.email?(other_user).must_equal true
  end

  it "uses the policy class name as the default namespace" do
    user = User.create!

    permission = Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(DefaultNamespacePolicy)
    )

    policy = DefaultNamespacePolicy.new(user)
    policy.view?.must_equal true
  end
end
