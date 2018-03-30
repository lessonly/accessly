require "test_helper"
require "accessly/policy/base"
describe Accessly::Policy::Base do

  class OverrideActionsUserPolicy < Accessly::Policy::Base

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

    def view
      if actor.name == "Aaron"
        User.all
      else
        super
      end
    end
  end

  it "allows general action checks to be customized" do
    # User named Aaron can always destroy users
    user = User.create!(name: "Aaron")
    policy = OverrideActionsUserPolicy.new(user)
    policy.destroy?.must_equal true
    policy.can?(:destroy).must_equal true

    # User not named Aaron gets normal privileges
    user = User.create!(name: "Jim")
    policy = OverrideActionsUserPolicy.new(user)
    policy.destroy?.must_equal false
    #policy.can?(:destroy).must_equal false
  end

  it "allows object action checks to be customized" do
    # Anybody can email user named Aaron
    user = User.create!
    other_user = User.create!(name: "Aaron")
    policy = OverrideActionsUserPolicy.new(user)
    policy.email?(other_user).must_equal true
    policy.can?(:email, other_user).must_equal true

    # Emailing other users goes through normal privilege check
    policy.email?(user).must_equal false
    policy.can?(:email, user).must_equal false
  end

  it "allows checks that are both general and on an object to be customized" do
    # User named Bob cannot generally change role
    user = User.create!(name: "Bob")
    other_user = User.create!(name: "Aaron")
    policy = OverrideActionsUserPolicy.new(user)
    policy.change_role?.must_equal false
    policy.can?(:change_role).must_equal false

    # User named Bob can change role for specific user named Aaron
    policy.change_role?(other_user).must_equal true
    policy.can?(:change_role, other_user).must_equal true

    # User named Aaron has normal privileges
    policy = OverrideActionsUserPolicy.new(other_user)
    policy.change_role?.must_equal false
    policy.can?(:change_role).must_equal false

    policy.change_role?(user).must_equal false
    policy.can?(:change_role, user).must_equal false
  end

  it "allows action lists to be overridden" do
    User.destroy_all

    # User named Aaron can view all users
    user = User.create!(name: "Aaron")

    # Other users cannot view any users
    other_user = User.create!(name: "Bob")

    OverrideActionsUserPolicy.new(user).view.order(:id).must_equal [user, other_user]
    OverrideActionsUserPolicy.new(user).list(:view).order(:id).must_equal [user, other_user]
    OverrideActionsUserPolicy.new(other_user).view.order(:id).must_equal []
    OverrideActionsUserPolicy.new(other_user).list(:view).order(:id).must_equal []
  end
end
