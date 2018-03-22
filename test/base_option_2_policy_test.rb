require "test_helper"
require "accessly/policy/base_option_2"

describe Accessly::Policy::BaseOption2 do
############
# NOTE TO SELF
# BaseOption2 implements an API like this:
# UserPolicy.new(user).can?(view)
# UserPolicy.new(user).can?(:view, other_user)
# UserPolicy.new(user).list(:view)
#
# BaseOption1 implements a slightly different way.
#
# We will need to decide which one to move forward with.
############

  class UserPolicyOption2 < Accessly::Policy::BaseOption2

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

    def self.object_type
      User
    end
  end

  class PolicyWithoutObjectTypeOption2 < Accessly::Policy::BaseOption2
    actions view: 1
  end

  it "defines action lookup methods" do
    user = User.create!
    other_user = User.create!

    UserPolicyOption2.new(user).can?(:view)
    UserPolicyOption2.new(user).can?(:edit_basic_info)
    UserPolicyOption2.new(user).can?(:change_role)
    UserPolicyOption2.new(user).can?(:destroy)

    UserPolicyOption2.new(user).can?(:view, other_user)
    UserPolicyOption2.new(user).can?(:edit_basic_info, other_user)
    UserPolicyOption2.new(user).can?(:change_role, other_user)
    UserPolicyOption2.new(user).can?(:email, other_user)
  end

  it "limits lookup methods to contexts with and without objects appropriately" do
    user = User.create!
    other_user = User.create!

    assert_raises(ArgumentError) do
      UserPolicyOption2.new(user).can?(:email)
    end

    assert_raises(ArgumentError) do
      UserPolicyOption2.new(user).can?(:destroy, other_user)
    end
  end

  it "requires object_type to be defined" do
    assert_raises(NotImplementedError) do
      PolicyWithoutObjectTypeOption2.new(User.new).can?(:view)
    end
  end

  it "looks up non-object permissions from the Accessly library" do
    user = User.create!

    UserPolicyOption2.new(user).can?(:edit_basic_info).must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    UserPolicyOption2.new(user).can?(:edit_basic_info).must_equal true
  end

  it "caches non-object permission lookups" do
    user = User.create!
    policy = UserPolicyOption2.new(user)

    policy.can?(:edit_basic_info).must_equal false

    permission = Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    policy.can?(:edit_basic_info).must_equal false

    policy = UserPolicyOption2.new(user)
    policy.can?(:edit_basic_info).must_equal true
    permission.destroy!
    policy.can?(:edit_basic_info).must_equal true
  end

  it "looks up object permissions from the Accessly library" do
    user = User.create!
    other_user = User.create!

    UserPolicyOption2.new(user).can?(:email, other_user).must_equal false

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    UserPolicyOption2.new(user).can?(:email, other_user).must_equal true
  end

  it "caches object permission lookups" do
    user = User.create!
    other_user = User.create!
    policy = UserPolicyOption2.new(user)

    policy.can?(:email, other_user).must_equal false

    permission = Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    policy.can?(:email, other_user).must_equal false

    policy = UserPolicyOption2.new(user)
    policy.can?(:email, other_user).must_equal true
    permission.destroy!
    policy.can?(:email, other_user).must_equal true
  end
end
