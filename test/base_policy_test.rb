require "test_helper"
require "accessly/policy/base"

describe Accessly::Policy::Base do

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

    def self.model_scope
      User.all
    end

    def unrestricted?
      actor.admin?
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
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    UserPolicy.new(user).edit_basic_info?.must_equal true
    UserPolicy.new(user).can?(:edit_basic_info).must_equal true
  end

  it "caches non-object permission lookups" do
    user = User.create!
    policy = UserPolicy.new(user)

    policy.edit_basic_info?.must_equal false
    policy.can?(:edit_basic_info).must_equal false

    permission = Accessly::PermittedAction.create!(
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    policy.edit_basic_info?.must_equal false
    policy.can?(:edit_basic_info).must_equal false

    policy = UserPolicy.new(user)
    policy.edit_basic_info?.must_equal true
    policy.can?(:edit_basic_info).must_equal true

    permission.destroy!
    policy.edit_basic_info?.must_equal true
    policy.can?(:edit_basic_info).must_equal true
  end

  it "looks up object permissions from the Accessly library" do
    user = User.create!
    other_user = User.create!

    UserPolicy.new(user).email?(other_user).must_equal false
    UserPolicy.new(user).can?(:email, other_user).must_equal false

    Accessly::PermittedActionOnObject.create!(
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    UserPolicy.new(user).email?(other_user).must_equal true
    UserPolicy.new(user).can?(:email, other_user).must_equal true
  end

  it "caches object permission lookups" do
    user = User.create!
    other_user = User.create!
    policy = UserPolicy.new(user)

    policy.email?(other_user).must_equal false
    policy.can?(:email, other_user).must_equal false

    permission = Accessly::PermittedActionOnObject.create!(
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    policy.email?(other_user).must_equal false
    policy.can?(:email, other_user).must_equal false

    policy = UserPolicy.new(user)
    policy.email?(other_user).must_equal true
    policy.can?(:email, other_user).must_equal true

    permission.destroy!
    policy.email?(other_user).must_equal true
    policy.can?(:email, other_user).must_equal true
  end

  it "uses the policy class name as the default namespace" do
    user = User.create!

    permission = Accessly::PermittedAction.create!(
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(DefaultNamespacePolicy)
    )

    policy = DefaultNamespacePolicy.new(user)
    policy.view?.must_equal true
    policy.can?(:view).must_equal true
  end

  it "returns true automatically when unrestricted? returns true" do
    admin_user = User.create!(admin: true)
    non_admin_user = User.create!

    # Non-admin has no permissions set
    non_admin_policy = UserPolicy.new(non_admin_user)
    non_admin_policy.view?.must_equal false
    non_admin_policy.can?(:view).must_equal false
    non_admin_policy.view?(admin_user).must_equal false
    non_admin_policy.can?(:view, admin_user).must_equal false


    # Admin has no permissions set, but can do anything
    admin_policy = UserPolicy.new(admin_user)
    admin_policy.view?.must_equal true
    admin_policy.can?(:view).must_equal true
    admin_policy.view?(non_admin_user).must_equal true
    admin_policy.can?(:view, non_admin_user).must_equal true
  end

  it "lists objects the actor has the permission on" do
    user = User.create!
    permitted_users = 3.times.map { User.create! }

    other_user = User.create!
    other_permitted_users = 3.times.map { User.create! }

    permitted_users.each do |permitted_user|
      Accessly::PermittedActionOnObject.create!(
        segment_id: -1,
        actor: user,
        action: 1,
        object_type: String(permitted_user.class),
        object_id: permitted_user.id
      )
    end

    other_permitted_users.each do |permitted_user|
      Accessly::PermittedActionOnObject.create!(
        segment_id: -1,
        actor: other_user,
        action: 1,
        object_type: String(permitted_user.class),
        object_id: permitted_user.id
      )
    end

    user_policy = UserPolicy.new(user)
    granted_users = user_policy.view.order(:id)
    granted_users.must_equal permitted_users
    (user_policy.list(:view).order(:id)).must_equal permitted_users

    other_user_policy = UserPolicy.new(other_user)
    other_granted_users = other_user_policy.view.order(:id)
    other_granted_users.must_equal other_permitted_users
    (other_user_policy.list(:view).order(:id)).must_equal other_permitted_users
  end

  it "allows unrestricted actors to list all objects in the scope" do
    User.destroy_all

    admin = User.create!(admin: true)
    all_users = [admin, *3.times.map { User.create! }]

    policy = UserPolicy.new(admin)
    granted_users = policy.view.order(:id)
    granted_users.must_equal all_users
    (policy.list(:view).order(:id)).must_equal all_users
  end
end
