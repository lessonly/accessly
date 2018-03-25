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

    # TODO: This will be necessary for list
    # def self.model_scope
    #   User
    # end

    # TODO: Grant
    # TODO: Revoke
  end

  class CustomizedPolicy < UserPolicy

    def self.namespace
      "OverriddenNamespace"
    end

    def is_admin?
      actor.admin?
    end

    # TODO: List
    # def self.admin_scope
    #   actor.company.users.select(:id)
    # end

    # def list
    #   if actor.admin?
    #     actor.company.users
    #   else
    #     super
    #   end
    # end

    # Customize a general action check
    def destroy?
      if actor.name == "Aaron"
        true
      else
        super
      end
    end

    # Customize a check that is both general and on an object
    def change_role?(object = nil)
      if object.nil?
        if actor.name == "Bob"
          false
        else
          super
        end
      elsif actor.name == "Bob" && object.name == "Aaron"
        true
      else
        super
      end
    end

    # Customize an object action check
    def email?(object)
      if object.name == "Aaron"
        true
      else
        super
      end
    end
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

  it "allows general action checks to be customized" do
    # User named Aaron can always destroy users
    user = User.create!(name: "Aaron")
    policy = CustomizedPolicy.new(user)
    policy.destroy?.must_equal true

    # User not named Aaron gets normal privileges
    user = User.create!(name: "Jim")
    policy = CustomizedPolicy.new(user)
    policy.destroy?.must_equal false
  end

  it "allows object action checks to be customized" do
    # Anybody can email user named Aaron
    user = User.create!
    other_user = User.create!(name: "Aaron")
    policy = CustomizedPolicy.new(user)
    policy.email?(other_user).must_equal true

    # Emailing other users goes through normal privilege check
    policy.email?(user).must_equal false
  end

  it "allows checks that are both general and on an object to be customized" do
    # User named Bob cannot generally change role
    user = User.create!(name: "Bob")
    other_user = User.create!(name: "Aaron")
    policy = CustomizedPolicy.new(user)
    policy.change_role?.must_equal false

    # User named Bob can change role for specific user named Aaron
    policy.change_role?(other_user).must_equal true

    # User named Aaron has normal privileges
    policy = CustomizedPolicy.new(other_user)
    policy.change_role?.must_equal false
    policy.change_role?(user).must_equal false
  end

  it "returns true automatically when is_admin? returns true" do
    admin_user = User.create!(admin: true)
    non_admin_user = User.create!

    # Non-admin has no permissions set
    non_admin_policy = CustomizedPolicy.new(non_admin_user)
    non_admin_policy.view?.must_equal false
    non_admin_policy.view?(admin_user).must_equal false

    # Admin has no permissions set, but can do anything
    admin_policy = CustomizedPolicy.new(admin_user)
    admin_policy.view?.must_equal true
    admin_policy.view?(non_admin_user).must_equal true
  end
end
